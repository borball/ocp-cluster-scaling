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

jinja2 "$BASEDIR"/templates/ns.yaml.j2 > "$BASEDIR"/ns.yaml
jinja2 "$BASEDIR"/templates/pull-secret.yaml.j2 > "$BASEDIR"/pull-secret.yaml
jinja2 "$BASEDIR"/templates/infraenv.yaml.j2 > "$BASEDIR"/infraenv.yaml
jinja2 "$BASEDIR"/templates/agent-cluster-install.yaml.j2 > "$BASEDIR"/agent-cluster-install.yaml
#jinja2 "$BASEDIR"/templates/kubeadmin-passwd-secret.yaml.j2 > "$BASEDIR"/kubeadmin-passwd-secret.yaml
jinja2 "$BASEDIR"/templates/kubeconfig-secret.yaml.j2 > "$BASEDIR"/kubeconfig-secret.yaml
jinja2 "$BASEDIR"/templates/cluster-deployment.yaml.j2 > "$BASEDIR"/cluster-deployment.yaml
jinja2 "$BASEDIR"/templates/managed-cluster.yaml.j2 > "$BASEDIR"/managed-cluster.yaml

echo "Will create CRs below, check the files to get more information."
ls -l "$BASEDIR"/*.yaml
oc apply -k "$BASEDIR"/
