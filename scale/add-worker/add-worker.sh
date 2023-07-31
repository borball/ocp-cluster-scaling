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

  jinja2 $templates/nmstate.yaml.j2
  jinja2 $templates/nmstate.yaml.j2 $config_file | oc apply -f -
fi

echo "Create agent to add host into InfraEnv"
jinja2 $templates/agent.yaml.j2 $config_file
jinja2 $templates/agent.yaml.j2 $config_file | oc apply -f -


#boot the node
../boot-iso.sh $(yq '.worker.bmc.address' $config_file) $(yq '.worker.bmc.username' $config_file):$(yq '.worker.bmc.password' $config_file) $(yq '.worker.bmc.kvm_uuid' $config_file)