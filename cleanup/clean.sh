#!/bin/bash
#
# script to clean up everything

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cluster_name=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
cluster_workspace="$BASEDIR"/../import/"$cluster_name"

echo "You are going to detach the managed cluster $cluster_name from the MCE hub, and delete the MultiClusterEngine hub, then delete the MCE operator."
echo
echo "Deleting managed cluster: $cluster_name"
oc delete -k "$cluster_workspace"/

echo
echo "Deleting MultiClusterEngine hub instance."
oc delete AgentServiceConfig agent
oc delete MultiClusterEngine multiclusterengine

sleep 30

echo
echo "Deleting MultiClusterEngine operator."
oc delete ip -n multicluster-engine --all
oc delete csv -n multicluster-engine --all
oc delete subs -n multicluster-engine --all
oc delete OperatorGroup -n multicluster-engine --all
# There is a bug that the operator could not be uninstalled automatically unless we delete the CRD first.
oc delete crd multiclusterengines.multicluster.openshift.io
oc delete operator multicluster-engine.multicluster-engine
sleep 20

echo
oc delete ns multicluster-engine
oc delete ns hive
echo

echo "Done."