#!/bin/bash
#
# - Delete a worker node
#

set -euo pipefail

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
export BASEDIR

usage(){
  echo "Usage: $0 worker-node"
  echo "Example 1: $0 worker0.compact.outbound.vz.bos2.lab"
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

cluster_name=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
namespace=$cluster_name
node="$1"

#delete agent from MCE hub
delete_agent(){
  local all_agents=$(oc get agent -n "$namespace" -o jsonpath='{range .items[*]}{.spec.hostname}|{.metadata.name}{"\n"}{end}')

  for line in $all_agents; do
    local hostname=$(echo "$line" | cut -d "|" -f1)
    local agent=$(echo "$line" | cut -d "|" -f2)
    if [ "$node" = "$hostname" ]; then
      echo "Will delete $agent"
      oc delete agent -n "$namespace" "$agent"
    fi
  done
}

delete_node(){
  echo "Will delete $node"
  oc delete node "$node"
}

delete_agent
delete_node

echo "Although the node object is now deleted from the cluster, it can still rejoin the cluster after reboot or if the kubelet service is restarted."
echo "To permanently delete the node and all its data, you must decommission the node."
echo "Ref: https://docs.openshift.com/container-platform/4.12/nodes/nodes/nodes-nodes-working.html#deleting-nodes"
echo