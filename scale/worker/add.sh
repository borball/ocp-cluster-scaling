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
 
kubeconfig_hub=$(yq '.hub.kubeconfig' $config_file)
kubeconfig_spoke=$(yq '.cluster.kubeconfig' $config_file)

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

nmstate=$(yq '.worker.nmstate // "" ' $config_file)
if [ ! -z $nmstate ]; then
  echo "Customized NMStateConfig CR provided: $nmstate"
  och apply -f $nmstate
else
  #create NMStateConfig for static IP based on template
  if [ "true" = "$(yq '.worker.dhcp' $config_file)" ]; then
    echo "New worker node uses DHCP, will not create NMStateConfig CR"
  else
    echo "New worker node uses static IP, will create NMStateConfig CR"

    jinja2 ./templates/nmstate.yaml.j2 $config_file
    jinja2 ./templates/nmstate.yaml.j2 $config_file | och apply -f -
  fi

fi

#boot the node
bmc_address=$(yq '.worker.bmc.address' $config_file)
bmc_username=$(yq '.master.bmc.username' $config_file)
bmc_password=$(yq '.master.bmc.password' $config_file)
iso_image=$(yq '.iso.address' $config_file)
kvm_uuid=$(yq '.worker.bmc.kvm_uuid // "" ' $config_file)

if [ ! -z $kvm_uuid ]; then
  ../boot-from-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image $kvm_uuid
else
  ../boot-from-iso.sh $bmc_address $bmc_username:$bmc_password $iso_image
fi

#TODO: check if an older agent already existed
until ( och get agent -n $namespace |grep -m 1 "auto-assign" ); do
  sleep 5
done

worker_hostname=$(yq '.worker.hostname' $config_file)
worker_disk=$(yq '.worker.disk // "" ' $config_file)

agent_name=$(och get agent -n $namespace -o jsonpath="{.items[?(@.spec.approved==false)].metadata.name}")

och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/hostname", "value": "'${worker_hostname}'" }]'
och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/approved", "value": true }]'
sleep 10
och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/role", "value": "worker" }]'

if [ ! -z $worker_disk ]; then
  och patch agent -n $namespace $agent_name --type=json --patch '[{ "op": "replace", "path": "/spec/installation_disk_id", "value": "'${worker_disk}'"}]'
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

ocs get nodes

