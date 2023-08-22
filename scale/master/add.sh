#!/bin/bash
# 
# Add a master and boot from discovery iso

usage(){
  echo "Usage: $0 [config.yaml]"
  echo "Example: $0 config-master0.yaml"
}

if [ $# -lt 1 ]
then
  usage
  exit
fi

if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then 
  usage
  exit
fi

config_file=$1;
 
kubeconfig_hub=$KUBECONFIG
kubeconfig_spoke=$KUBECONFIG

ocs() {
    oc --kubeconfig $kubeconfig_spoke "$@"
}
export -f ocs

och() {
    oc --kubeconfig $kubeconfig_hub "$@"
}
export -f och

echo "Current cluster information"
echo
ocs get nodes
echo
ocs get clusterversion
echo
export cluster_name=$(yq '.cluster.name' $config_file)
export namespace=$cluster_name

nmstate=$(yq '.master.nmstate // "" ' $config_file)

if [ ! -z $nmstate ]; then
  echo "Customized NMStateConfig CR provided: $nmstate"
  och apply -f $nmstate
else
  ##create NMStateConfig for static IP
  if [ "true" = "$(yq '.master.dhcp' $config_file)" ]; then
    echo "New master node uses DHCP, will not create NMStateConfig CR"
  else
    echo "New master node uses static IP, will create NMStateConfig CR"

    jinja2 ./templates/nmstate.yaml.j2 $config_file
    jinja2 ./templates/nmstate.yaml.j2 $config_file | och apply -f -
  fi
fi

#boot the node
bmc_address=$(yq '.master.bmc.address' $config_file)
bmc_username=$(yq '.master.bmc.username' $config_file)
bmc_password=$(yq '.master.bmc.password' $config_file)
iso_image=$(yq '.iso.address' $config_file)
kvm_uuid=$(yq '.master.bmc.kvm_uuid // "" ' $config_file)

if [ ! -z $kvm_uuid ]; then
  ../boot-from-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image $kvm_uuid
else
  ../boot-from-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image
fi

#TODO: check if an older agent already existed
until ( och get agent -n $namespace |grep -m 1 "auto-assign" ); do
  sleep 5
done

master_hostname=$(yq '.master.hostname' $config_file)
master_disk=$(yq '.master.disk // "" ' $config_file)

agent_name=$(och get agent -n $namespace -o jsonpath="{.items[?(@.spec.approved==false)].metadata.name}")

och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/hostname", "value": "'${master_hostname}'" }]'
och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/approved", "value": true }]'
sleep 10
och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/role", "value": "master" }]'

if [ ! -z $master_disk ]; then
  och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/installation_disk_id", "value": "'${master_disk}'"}]'
fi

#Trigger the installation
och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/clusterDeploymentName", "value": {"name": "'${cluster_name}'", "namespace": "'${namespace}'"} }]'

echo "-------------------------------"

#Monitor the installation progress
while [[ "Done" != $(och get agent -n $namespace $agent_name -o jsonpath='{..currentStage}') ]]; do
  installationPercentage=$(och get agent -n $namespace $agent_name -o jsonpath='{..installationPercentage}')
  echo "Installation in progress: completed $installationPercentage/100"
  sleep 15
done

echo "Installation completed."
echo
echo "Afet adding the node:"

ocs get nodes
echo

#create bmh and machine
infra_id=$(och get -n $namespace ClusterDeployment -o jsonpath={..infraID})

new_hostname_full=$(yq '.master.hostname' $config_file)
new_hostname_short=$(echo $new_hostname_full |cut -d '.' -f 1)

export new_machine_name="$infra_id-$new_hostname_short"

replaced_master_hostname=$(yq '.master.replaced' $config_file)
export boot_mode=$(ocs get bmh -n openshift-machine-api $replaced_master_hostname -o jsonpath={.spec.bootMode})
replaced_machine_name=$(ocs get bmh -n openshift-machine-api $replaced_master_hostname -o jsonpath={.spec.consumerRef.name})

jinja2 ./templates/baremetal-host.yaml.j2 $config_file | ocs apply -f -
jinja2 ./templates/machine.yaml.j2 $config_file | ocs apply -f -

./link-machine-and-node.sh $kubeconfig_spoke $new_machine_name $new_hostname_full

sleep 30

# node is in ready status
if [ "True" = $(ocs get nodes $replaced_master_hostname -o jsonpath="{.status.conditions[?(@.type=='Ready')].status}") ]; then
  read -p "Please shutdown the master node which is going to be replaced. continue if it's been down(y/n)?" choice
  case "$choice" in
    y|Y ) echo "yes";;
    n|N ) echo "no";;
    * ) echo "invalid";;
  esac
fi

echo "OpenShift may take a while to roll out the cluster operators on the new node."

#find a healthy one
etcd_pod=$(ocs get pod -n openshift-etcd --selector app=etcd --field-selector status.phase=Running,metadata.name!=etcd-$replaced_master_hostname,metadata.name!=etcd-$new_hostname_full -o jsonpath="{.items[0].metadata.name}")

ocs rsh -n openshift-etcd $etcd_pod etcdctl member list -w table
etcd_delete_member=$(ocs rsh -n openshift-etcd $etcd_pod etcdctl member list |grep $replaced_master_hostname |cut -d ',' -f 1)
ocs rsh -n openshift-etcd $etcd_pod etcdctl member remove $etcd_delete_member
ocs rsh -n openshift-etcd $etcd_pod etcdctl member list -w table

sleep 30
ocs delete bmh -n openshift-machine-api $replaced_master_hostname
ocs delete machine -n openshift-machine-api $replaced_machine_name
sleep 30

#speed up the rolling out
ocs delete -n openshift-etcd pod --all --force --grace-period=0
sleep 30

echo "You can type ctrl+c to stop the watch below:"

ocs get co -w

