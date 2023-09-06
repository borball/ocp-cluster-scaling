#!/bin/bash
#
# script to clean up everything

usage(){
  echo "Usage: $0 cluster"
  echo "Example: $0 compact"
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

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cluster_name=$1
cluster_workspace="$BASEDIR"/../import/"$cluster_name"

echo "You are going to detach the managed cluster $cluster_name from the MCE hub."

echo "Deleting managed cluster: $cluster_name"
oc delete -k "$cluster_workspace"/

echo "Deleting MultiClusterEngine instance."
oc delete MultiClusterEngine multiclusterengine

echo "Deleting MultiClusterEngine operator."
oc delete ip -n multicluster-engine --all
oc delete csv -n multicluster-engine --all
oc delete subs -n multicluster-engine --all
oc delete OperatorGroup -n multicluster-engine --all
oc delete ns multicluster-engine


