#!/bin/bash
#
# - Add a new node, can be master or worker
# - create NMStateConfig
# - generate discovery ISO
# - boot the node from discovery ISO
# - trigger the OCP deployment and monitor the installation progress
#

set -euo pipefail

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
export BASEDIR

usage(){
  echo "Usage: $0 config.yaml [nm-state.yaml]"
  echo "     config.yaml: mandatory, refer to config-sample.yaml"
  echo "     nm-state.yaml: optional, refer to https://github.com/openshift/assisted-service/blob/master/config/crd/bases/agent-install.openshift.io_nmstateconfigs.yaml"
  echo "Example 1: $0 config-worker1.yaml"
  echo "Example 2: $0 config-master3.yaml nm-state-master3.yaml"
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
nm_state=""
if [ $# -eq 2 ]; then
  nm_state=$2
fi

export_cluster_info(){
  cluster_name=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
  namespace=$cluster_name
  export cluster_name

  local hostname=$(yq '.node.hostname' "$config_file")
  export node_hostname="$hostname"
}

print_cluster_info(){
  echo "-------------------------------"
  echo "Cluster information:"
  oc get clusterversion
  echo
  echo "Cluster nodes:"
  oc get nodes
  echo
}

create_nm(){
  echo "-------------------------------"
  #If a NMStateConfig is specified
  if [ -n "$nm_state" ]; then
    echo "Customized NMStateConfig CR provided: $nm_state"
    cat "$nm_state"
    oc apply -f "$nm_state"
  else
    #use default template
    local network=$(yq '.node.network // "" ' "$config_file")
    if [ -z "$network" ]; then
      #create NMStateConfig for static IP based on template
      echo "Customized NMStateConfig CR not provided, new node uses DHCP, will not create NMStateConfig CR."
    else
      echo "Customized NMStateConfig CR not provided, new node uses static IP, will create NMStateConfig CR below:"
      jinja2 "$BASEDIR"/templates/nmstate.yaml.j2 "$config_file"
      jinja2 "$BASEDIR"/templates/nmstate.yaml.j2 "$config_file" | oc apply -n "$namespace" -f -
    fi
  fi
}

boot_node(){
  echo "-------------------------------"
  local bmc_address=$(yq '.node.bmc.address' "$config_file")
  local bmc_username=$(yq '.node.bmc.username' "$config_file")
  local bmc_password=$(yq '.node.bmc.password' "$config_file")
  local iso_image=$(oc get infraenv -n "$namespace" -o json|jq -r '.items[0].status.isoDownloadURL')

  #Due to some bugs https://issues.redhat.com/browse/MGMT-14923, the isoDownloadURL is always pointing to the current latest OCP version(4.13 at this point).
  #Need to manually change to 4.12 to avoid issues
  iso_image=${iso_image//4.13/4.12}
  
  local kvm_uuid=$(yq '.node.bmc.kvm_uuid // "" ' $config_file)
  
  if [ -n "$kvm_uuid" ]; then
    "$BASEDIR"/boot-from-iso.sh "$bmc_address" "$bmc_username":"$bmc_password" "$iso_image" "$kvm_uuid"
  else
    "$BASEDIR"/boot-from-iso.sh "$bmc_address" "$bmc_username":"$bmc_password" "$iso_image"
  fi
}

patch_agent(){
  echo "-------------------------------"

  #TODO: check if an older agent already existed
  until ( oc get agent -n "$namespace" 2>/dev/null |grep -m 1 "auto-assign" ); do
    sleep 15
  done

  echo "Patching the agent to approve the node and trigger the deployment."
  local role=$(yq '.node.role' "$config_file")
  local install_disk=$(yq '.node.disk // "" ' "$config_file")

  agent_name=$(oc get agent -n "$namespace" -o jsonpath="{.items[?(@.spec.approved==false)].metadata.name}")

  echo "patch /spec/hostname with: ${node_hostname}"
  oc patch agent -n "$namespace" "$agent_name" --type=json --patch '[{ "op": "replace", "path": "/spec/hostname", "value": "'"${node_hostname}"'" }]'
  echo "patch /spec/approved with: true"
  oc patch agent -n "$namespace" "$agent_name" --type=json --patch '[{ "op": "replace", "path": "/spec/approved", "value": true }]'
  sleep 10
  echo "patch /spec/role with: ${role}"
  oc patch agent -n "$namespace" "$agent_name" --type=json --patch '[{ "op": "replace", "path": "/spec/role", "value": "'"${role}"'" }]'

  if [ -n "$install_disk" ]; then
    echo "patch /spec/installation_disk_id with ${node_disk}"
    oc patch agent -n "$namespace" "$agent_name" --type=json --patch '[{ "op": "replace", "path": "/spec/installation_disk_id", "value": "'"${node_disk}"'"}]'
  fi

  #Trigger the installation
  echo "patch /spec/clusterDeploymentName with {\"name\": \"${cluster_name}\", \"namespace\": \"${namespace}\"}"
  oc patch agent -n "$namespace" "$agent_name" --type=json --patch '[{ "op": "replace", "path": "/spec/clusterDeploymentName", "value": {"name": "'"${cluster_name}"'", "namespace": "'"${namespace}"'"} }]'
}

monitor_install(){
  echo "-------------------------------"
  while [[ "Done" != $(oc get agent -n "$namespace" "$agent_name" -o jsonpath='{..currentStage}') ]]; do
    local installation_percentage=$(oc get agent -n "$namespace" "$agent_name" -o jsonpath='{..installationPercentage}')
    echo "Installation in progress: completed $installation_percentage/100"
    sleep 45
  done
  echo "Installation completed."
  echo
}

print_cluster_info
export_cluster_info
create_nm
sleep 20
boot_node
patch_agent
monitor_install
print_cluster_info




