#!/bin/bash
# 
# Download discovery iso

usage(){
  echo "Usage: $0 <hub-kubeconfig> <cluster-name>"
  echo "Example: $0 compact-kubeconfig.yaml compact"
}

if [ $# -lt 2 ]
then
  usage
  exit
fi

if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then 
  usage
  exit
fi

kubeconfig=$1
cluster=$2

cluster_crt=$(oc --kubeconfig $kubeconfig get secret router-ca -o json -n openshift-ingress-operator |jq -r ".data.\"tls.crt\""|base64 -d)
sudo echo $cluster_crt > /etc/pki/ca-trust/source/anchors/$cluster.crt
sudo update-ca-trust

#Due to some bugs https://issues.redhat.com/browse/MGMT-14923, the isoDownloadURL is always pointing to the current latest OCP version(4.13 at this point). 
#Need to manually change to 4.12 to avoid issues
isoDownloadURL=$(oc --kubeconfig $kubeconfig get infraenv -n $cluster -o json|jq -r '.items[0].status.isoDownloadURL')

#fix bug
isoDownloadURL=${isoDownloadURL//4.13/4.12}

wget -O discovery.iso "$isoDownloadURL"

#wget -O /var/www/html/iso/compact-discovery.iso "$isoDownloadURL"