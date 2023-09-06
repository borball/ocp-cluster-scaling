#!/bin/bash
#
# script to clean up everything

echo "You are going to detach the managed cluster from the MCE hub."

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cluster_name=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
cluster_workspace="$BASEDIR"/../import/"$cluster_name"

echo "Delete managed cluster: $cluster_name"
oc delete -k "$cluster_workspace"/

echo "Delete MultiClusterEngine instance."
oc delete MultiClusterEngine multiclusterengine

echo "Delete MultiClusterEngine operator."
oc delete ip -n multicluster-engine --all
oc delete csv -n multicluster-engine --all
oc delete subs -n multicluster-engine --all
oc delete OperatorGroup -n multicluster-engine --all
oc delete ns multicluster-engine


