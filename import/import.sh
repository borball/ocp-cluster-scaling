#!/bin/bash
#
# script to import the cluster into the MCE hub


if ! type "yq" > /dev/null; then
  echo "Cannot find yq in the path, please install yq on the node first. ref: https://github.com/mikefarah/yq#install"
fi

usage(){
  echo "Usage: $0"
  echo "Example: $0"
}

if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then 
  usage
  exit
fi

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

export cluster_name=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
export namespace=$cluster_name
export pull_secret=$(oc get secrets -n openshift-config pull-secret -o jsonpath={.data.\\.dockerconfigjson})
export ssh_key=$(oc get mc 99-master-ssh -o jsonpath={..sshAuthorizedKeys[0]})
export domain=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq '.baseDomain')
export ocp_version=$(oc version -o json |jq -r '.openshiftVersion')
export imageset=img${ocp_version}-x86-64-appsub

#Need to handle case which platform is None.
export api_vip=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".platform.baremetal.apiVIP")
#Need to handle case which platform is None.
export ingress_vip=$(oc get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".platform.baremetal.ingressVIP")
export cluster_id=$(oc get clusterversion version -o json | jq .spec.clusterID )
export infra_id=$(oc get infrastructure cluster -o json | jq .status.infrastructureName)
#export username=$(echo $spoke_admin |base64)
#export password=$(echo $spoke_password |base64 -w 0)
export kubeconfig_secret=$(oc get secrets -n openshift-kube-apiserver node-kubeconfigs -o jsonpath={..lb-ext\\.kubeconfig})

cluster_workspace="$BASEDIR"/"$cluster_name"
mkdir -p "$cluster_workspace"

jinja2 "$BASEDIR"/templates/ns.yaml.j2 > "$cluster_workspace"/ns.yaml
jinja2 "$BASEDIR"/templates/pull-secret.yaml.j2 > "$cluster_workspace"/pull-secret.yaml
jinja2 "$BASEDIR"/templates/infraenv.yaml.j2 > "$cluster_workspace"/infraenv.yaml
jinja2 "$BASEDIR"/templates/agent-cluster-install.yaml.j2 > "$cluster_workspace"/agent-cluster-install.yaml
#jinja2 "$BASEDIR"/templates/kubeadmin-passwd-secret.yaml.j2 > "$cluster_workspace"/kubeadmin-passwd-secret.yaml
jinja2 "$BASEDIR"/templates/kubeconfig-secret.yaml.j2 > "$cluster_workspace"/kubeconfig-secret.yaml
jinja2 "$BASEDIR"/templates/cluster-deployment.yaml.j2 > "$cluster_workspace"/cluster-deployment.yaml
jinja2 "$BASEDIR"/templates/managed-cluster.yaml.j2 > "$cluster_workspace"/managed-cluster.yaml
cp "$BASEDIR"/kustomization.yaml "$cluster_workspace"/

echo "Will create CRs below, check the files to get more information."
ls -l "$cluster_workspace"/
oc apply -k "$cluster_workspace"/

echo
oc get mcl
echo
echo "Run oc get mcl -w to monitor that if the cluster will be imported and joined properly."
echo
