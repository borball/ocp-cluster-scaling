#!/bin/bash
#
# script to clean up everything

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cluster_name=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
cluster_workspace="$BASEDIR"/../import/"$cluster_name"

echo "You are going to detach the managed cluster $cluster_name from the MCE hub."

echo "Deleting managed cluster: $cluster_name"
oc delete -k "$cluster_workspace"/

echo "Deleting MultiClusterEngine instance."
oc delete AgentServiceConfig agent
oc delete MultiClusterEngine multiclusterengine

sleep 30

echo "Deleting MultiClusterEngine operator."
oc delete ip -n multicluster-engine --all
oc delete csv -n multicluster-engine --all
oc delete subs -n multicluster-engine --all
oc delete OperatorGroup -n multicluster-engine --all
sleep 20
oc delete ns multicluster-engine
