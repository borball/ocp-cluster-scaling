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

#create nmstateconfig for static IP
if [ "true" = "$(yq '.master.dhcp' $config_file)" ]; then
  echo "Master node uses DHCP, will not create nmstateconfig"
else
  echo "Master node uses static IP, will create nmstateconfig"

  jinja2 ./nmstate.yaml.j2 $config_file 
  jinja2 ./nmstate.yaml.j2 $config_file | oc apply -f -
fi


#boot the node
bmc_address=$(yq '.master.bmc.address' $config_file)
bmc_username=$(yq '.master.bmc.address' $config_file)
bmc_password=$(yq '.master.bmc.address' $config_file)
iso_image=$(yq '.iso.address' $config_file)
kvm_uuid=$(yq '.master.bmc.kvm_uuid' $config_file)

../boot-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image $kvm_uuid


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

#create bmh and machine
infra_id=$(oc get -n $namespace ClusterDeployment -o jsonpath={..infraID})
export machine_name="$infra_id-master-9"
replaced_master=$(yq '.master.replaced' $config_file)
export boot_mode=$(oc get bmh -n openshift-machine-api $replaced_master -o jsonpath={.spec.bootMode})

jinja2 ./baremetal-host.yaml.j2 $config_file 
jinja2 ./baremetal-host.yaml.j2 $config_file | oc apply -f -

jinja2 ./machine.yaml.j2 $config_file
jinja2 ./machine.yaml.j2 $config_file | oc apply -f -

new_host=$(yq '.master.hostname' $config_file)
./link-machine-and-node.sh $machine_name $new_host

oc rsh -n openshift-etcd etcd-$new_host etcdctl member list -w table

#oc delete bmh -n openshift-machine-api $replaced_master
#oc delete machine -n openshift-machine-api compact-84mqw-master-2

#oc get nodes