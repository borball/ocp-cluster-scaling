#!/bin/bash
# 
# Add a worker and boot from discovery iso

usage(){
  echo "Usage: $0 [config.yaml]"
  echo "Example: $0 config-worker1.yaml"
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
if [ "true" = "$(yq '.worker.dhcp' $config_file)" ]; then
  echo "Worker node uses DHCP, will not create nmstateconfig"
else
  echo "Worker node uses static IP, will create nmstateconfig"

  jinja2 ./nmstate.yaml.j2 $config_file 
  jinja2 ./nmstate.yaml.j2 $config_file | oc apply -f -
fi


#boot the node
bmc_address=$(yq '.worker.bmc.address' $config_file)
bmc_username=$(yq '.worker.bmc.address' $config_file)
bmc_password=$(yq '.worker.bmc.address' $config_file)
iso_image=$(yq '.iso.address' $config_file)
kvm_uuid=$(yq '.worker.bmc.kvm_uuid' $config_file)

../boot-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image $kvm_uuid


until ( oc get agent -n $namespace |grep -m 1 "auto-assign" ); do
  echo -n "."
  sleep 1
done

worker_hostname=$(yq '.worker.hostname' $config_file)
worker_disk=$(yq '.worker.disk // "" ' $config_file)

agent_name=$(oc get agent -n $namespace -o jsonpath="{.items[?(@.spec.approved==false)].metadata.name}")

oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/hostname", "value": "'${worker_hostname}'" }]'
oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/approved", "value": true }]'
sleep 10
oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/role", "value": "worker" }]'

if [ ! -z $worker_disk ]; then
  oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/installation_disk_id", "value": "'${worker_disk}'"}]'
fi

#Trigger the installation
oc patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/clusterDeploymentName", "value": {"name": "'${cluster_name}'", "namespace": "'${namespace}'"} }]'

#Monitor the installation progress
while [[ "Done" != $(oc patch agent -n $namespace $agent_name -o jsonpath='..currentStage') ]]; do
  echo "-------------------------------"
  installationPercentage=$(oc get agent -n $namespace $agent_name -o jsonpath='..installationPercentage')
  echo "Installation in progress: completed $installationPercentage/100"
  sleep 15
done

echo "Installation completed."
