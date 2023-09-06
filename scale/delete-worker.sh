#!/bin/bash
#
# - Delete a node added by add-node.sh, can be master or worker
#

set -euo pipefail

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
export BASEDIR

usage(){
  echo "Usage: $0 config.yaml"
  echo "     config.yaml: mandatory, refer to config-sample.yaml"
  echo "Example 1: $0 config-worker1.yaml"
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
kubeconfig_spoke=$(yq '.managed.kubeconfig' $config_file)

ocs() {
    oc --kubeconfig $kubeconfig_spoke "$@"
}
export -f ocs

och() {
    oc --kubeconfig $kubeconfig_hub "$@"
}
export -f och

export_cluster_info(){
  cluster_name=$(ocs get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
  namespace=$cluster_name
  node=$(yq '.node.hostname' "$config_file")
}

#delete agent from MCE hub
delete_agent(){
  local all_agents=$(och get agent -n "$namespace" -o jsonpath='{range .items[*]}{.spec.hostname}|{.metadata.name}{"\n"}{end}')

  for line in $all_agents; do
    local hostname=$(echo "$line" | cut -d "|" -f1)
    local agent=$(echo "$line" | cut -d "|" -f2)
    if [ "$node" = "$hostname" ]; then
      echo "Deleting agent $agent"
      och delete agent -n "$namespace" "$agent"
    fi
  done
  echo
}

delete_node(){
  echo "Deleting node $node"
  ocs delete node "$node"
  echo
}

list_nodes(){
  echo "Cluster nodes:"
  ocs get nodes
  echo
}

list_nodes
delete_agent
delete_node
list_nodes

echo
echo "*********************************"
echo "Although the node object is now deleted from the cluster, it can still rejoin the cluster after reboot or if the kubelet service is restarted."
echo "To permanently delete the node and all its data, you must decommission the node."
echo "Reference: https://docs.openshift.com/container-platform/4.12/nodes/nodes/nodes-nodes-working.html#deleting-nodes"
echo