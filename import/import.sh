#!/bin/bash
#
# script to import the cluster into the MCE hub

if ! type "yq" > /dev/null; then
  echo "Cannot find yq in the path, please install yq on the node first. ref: https://github.com/mikefarah/yq#install"
fi

usage(){
  echo "Usage: $0 [hub cluster kubeconfig] [spoke cluster kubeconfig] [admin of spoke cluster] [password of spoke cluster]"
  echo "If the hub cluster kubeconfig equals to spoke cluster kubeconfig, it means you will use the cluster itself as MCE hub and expand the cluster itself."
  echo "Example: $0 kubeconfig-hub.yaml kubeconfig-spoke.yaml kubeadmin A5tmu-sy4GG-yeajX-TgfVr"
}

if [ $# -lt 4 ]
then
  usage
  exit
fi

if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then 
  usage
  exit
fi

kubeconfig_hub=$1
kubeconfig_spoke=$2
spoke_admin=$3
spoke_password=$4

ocs() {
    oc --kubeconfig=$kubeconfig_spoke "$@"
}
export -f ocs

och() {
    oc --kubeconfig=$kubeconfig_spoke "$@"
}
export -f och

export cluster_name=$(ocs get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".metadata.name")
export namespace=$cluster_name
export pull_secret=$(ocs get secrets -n openshift-config pull-secret -o jsonpath={.data.\\.dockerconfigjson})
export ssh_key=$(ocs get mc 99-master-ssh -o jsonpath={..sshAuthorizedKeys[0]})
export domain=$(ocs get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq '.baseDomain')
export ocp_version=$(ocs version -o json |jq -r '.openshiftVersion')
export imageset=img${ocp_version}-x86-64-appsub
export api_vip=$(ocs get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".platform.baremetal.apiVIP")
export ingress_vip=$(ocs get cm -n kube-system cluster-config-v1 -o jsonpath={..install-config} |yq ".platform.baremetal.ingressVIP")
export cluster_id=$(ocs get clusterversion version -o json | jq .spec.clusterID )
export infra_id=$(ocs get infrastructure cluster -o json | jq .status.infrastructureName)
export username=$(echo $spoke_admin |base64)
export password=$(echo $spoke_password |base64 -w 0)
export kubeconfig_secret=$(ocs get secrets -n openshift-kube-apiserver node-kubeconfigs -o jsonpath={..lb-ext\\.kubeconfig})

jinja2 ./templates/ns.yaml.j2 > ./ns.yaml
jinja2 ./templates/pull-secret.yaml.j2 > ./pull-secret.yaml
jinja2 ./templates/infraenv.yaml.j2 > ./infraenv.yaml
jinja2 ./templates/agent-cluster-install.yaml.j2 > ./agent-cluster-install.yaml
jinja2 ./templates/kubeadmin-passwd-secret.yaml.j2 > ./kubeadmin-passwd-secret.yaml
jinja2 ./templates/kubeconfig-secret.yaml.j2 > ./kubeconfig-secret.yaml
jinja2 ./templates/cluster-deployment.yaml.j2 > ./cluster-deployment.yaml

if [ "$kubeconfig_hub" = "$kubeconfig_spoke" ]; then
  echo "hub cluster kubeconfig = spoke cluster kubeconfig, will use 'local-cluster' as the imported cluster."
  cp ./templates/kustomization-local-cluster.yaml ./kustomization.yaml
else
  jinja2 ./templates/managed-cluster.yaml.j2 > ./managed-cluster.yaml
  cp ./templates/kustomization-dedicated-cluster.yaml ./kustomization.yaml
fi

och apply -k ./
