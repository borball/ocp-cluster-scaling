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
 
kubeconfig=$(yq '.hub.kubeconfig' $config_file)
export KUBECONFIG=$kubeconfig

export cluster_name=$(yq '.cluster.name' $config_file)
export namespace=$cluster_name

##create nmstateconfig for static IP
if [ "true" = "$(yq '.master.dhcp' $config_file)" ]; then
  echo "Master node uses DHCP, will not create nmstateconfig"
else
  echo "Master node uses static IP, will create nmstateconfig"

  jinja2 ./templates/nmstate.yaml.j2 $config_file
  jinja2 ./templates/nmstate.yaml.j2 $config_file | oc apply -f -
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
until ( oc get agent -n $namespace |grep -m 1 "auto-assign" ); do
  sleep 5
done

master_hostname=$(yq '.master.hostname' $config_file)
master_disk=$(yq '.master.disk // "" ' $config_file)

agent_name=$(oc get agent -n $namespace -o jsonpath="{.items[?(@.spec.approved==false)].metadata.name}")

oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/hostname", "value": "'${master_hostname}'" }]'
oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/approved", "value": true }]'
sleep 10
oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/role", "value": "master" }]'

if [ ! -z $master_disk ]; then
  oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/installation_disk_id", "value": "'${master_disk}'"}]'
fi

#Trigger the installation
oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/clusterDeploymentName", "value": {"name": "'${cluster_name}'", "namespace": "'${namespace}'"} }]'

echo "-------------------------------"

#Monitor the installation progress
while [[ "Done" != $(oc get agent -n $namespace $agent_name -o jsonpath='{..currentStage}') ]]; do
  installationPercentage=$(oc get agent -n $namespace $agent_name -o jsonpath='{..installationPercentage}')
  echo "Installation in progress: completed $installationPercentage/100"
  sleep 15
done

echo "Installation completed."

oc get nodes

echo

#create bmh and machine
infra_id=$(oc get -n $namespace ClusterDeployment -o jsonpath={..infraID})

new_hostname_full=$(yq '.master.hostname' $config_file)
new_hostname_short=$(echo $new_hostname_full |cut -d '.' -f 1)

export new_machine_name="$infra_id-$new_hostname_short"

replaced_master_hostname=$(yq '.master.replaced' $config_file)
export boot_mode=$(oc get bmh -n openshift-machine-api $replaced_master_hostname -o jsonpath={.spec.bootMode})
replaced_machine_name=$(oc get bmh -n openshift-machine-api $replaced_master_hostname -o jsonpath={.spec.consumerRef.name})

jinja2 ./templates/baremetal-host.yaml.j2 $config_file | oc apply -f -
jinja2 ./templates/machine.yaml.j2 $config_file | oc apply -f -

./link-machine-and-node.sh $new_machine_name $new_hostname_full

sleep 30

# node is in ready status
if [ "True" = $(oc get nodes $replaced_master_hostname -o jsonpath="{.status.conditions[?(@.type=='Ready')].status}") ]; then
  read -p "Please shutdown the master node which is going to be replace. continue if it's been down(y/n)?" choice
  case "$choice" in
    y|Y ) echo "yes";;
    n|N ) echo "no";;
    * ) echo "invalid";;
  esac
fi

echo "You can shutdown the server which shall be replaced, OpenShift may take a while to roll out the cluster operators on the new node."

#find a healthy one
etcd_pod=$(oc get pod -n openshift-etcd --selector app=etcd --field-selector status.phase=Running,metadata.name!=etcd-$replaced_master_hostname,metadata.name!=etcd-$new_hostname_full -o jsonpath="{.items[0].metadata.name}")

oc rsh -n openshift-etcd $etcd_pod etcdctl member list -w table
etcd_delete_member=$(oc rsh -n openshift-etcd $etcd_pod etcdctl member list |grep $replaced_master_hostname |cut -d ',' -f 1)
oc rsh -n openshift-etcd $etcd_pod etcdctl member remove $etcd_delete_member
oc rsh -n openshift-etcd $etcd_pod etcdctl member list -w table

oc delete bmh -n openshift-machine-api $replaced_master_hostname
oc delete machine -n openshift-machine-api $replaced_machine_name

echo "You can shutdown the server which shall be replaced, OpenShift may take a while to roll out the cluster operators on the new node."

#ssh 192.168.58.14 'kcli stop vm vm5'

echo "You can type ctrl+c to stop the watch below:"

oc get co -w

