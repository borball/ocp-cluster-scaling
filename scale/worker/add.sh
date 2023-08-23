#!/bin/bash
# 
# Add a worker and boot from discovery iso

set -euo pipefail

usage(){
  echo "Usage: $0 config.yaml [nmstate.yaml]"
  echo "       config.yaml is mandatory, nmstate.yaml is optional"
  echo "Example 1: $0 config-worker1.yaml"
  echo "Example 2: $0 config-worker1.yaml nmstate-worker1.yaml"
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

nmstate=""
config_file=$1;
if [ $# -eq 2 ]
then
  nmstate=$2
fi

echo "Current cluster information"
echo
oc get nodes
echo
oc get clusterversion
echo

export cluster_name=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
export namespace=$cluster_name

#If a NMStateConfig is specified
if [ ! -z $nmstate ]; then
  echo "Customized NMStateConfig CR provided: $nmstate"
  oc apply -f $nmstate
else
  #use default template
  network=$(yq '.worker.network // "" ' $config_file)
  if [ -z "$network" ]; then
    #create NMStateConfig for static IP based on template
    echo "New worker node uses DHCP, will not create NMStateConfig CR"
  else
    echo "New worker node uses static IP, will create NMStateConfig CR"
    jinja2 ./templates/nmstate.yaml.j2 $config_file
    jinja2 ./templates/nmstate.yaml.j2 $config_file | oc apply -f -
  fi
fi

#boot the node
bmc_address=$(yq '.worker.bmc.address' $config_file)
bmc_username=$(yq '.master.bmc.username' $config_file)
bmc_password=$(yq '.master.bmc.password' $config_file)
#use the assisted-image service
iso_image=$(oc get infraenv -n $cluster_name -o json|jq -r '.items[0].status.isoDownloadURL')
#Due to some bugs https://issues.redhat.com/browse/MGMT-14923, the isoDownloadURL is always pointing to the current latest OCP version(4.13 at this point).
#Need to manually change to 4.12 to avoid issues
iso_image=${iso_image//4.13/4.12}

kvm_uuid=$(yq '.worker.bmc.kvm_uuid // "" ' $config_file)

if [ ! -z $kvm_uuid ]; then
  ../boot-from-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image $kvm_uuid
else
  ../boot-from-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image
fi

#TODO: check if an older agent already existed
until ( oc get agent -n $namespace |grep -m 1 "auto-assign" ); do
  sleep 5
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

echo "-------------------------------"

#Monitor the installation progress
while [[ "Done" != $(oc get agent -n $namespace $agent_name -o jsonpath='{..currentStage}') ]]; do
  installationPercentage=$(oc get agent -n $namespace $agent_name -o jsonpath='{..installationPercentage}')
  echo "Installation in progress: completed $installationPercentage/100"
  sleep 15
done

echo "Installation completed."
echo

oc get nodes

