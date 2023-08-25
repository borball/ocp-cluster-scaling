#!/bin/bash
#
# - Replace a master with the new added one
#

set -euo pipefail

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
export BASEDIR=$BASEDIR

usage(){
  echo "Usage: $0 replaced-master new-master"
  echo "Example: $0 master0.compact.outbound.vz.bos2.lab master3.compact.outbound.vz.bos2.lab"
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

replaced_master_hostname=$1
new_master_hostname=$2
export new_master_hostname="$new_master_hostname"

print_cluster_info(){
  echo "-------------------------------"
  echo "Cluster information:"
  oc get clusterversion
  echo
  echo "Cluster nodes:"
  oc get nodes
  echo
  echo "Cluster operators:"
  oc get co
  echo
}

export_cluster_info(){
  local boot_mode=$(oc get bmh -n openshift-machine-api "$replaced_master_hostname" -o jsonpath={.spec.bootMode})
  export boot_mode="$boot_mode"

  replaced_machine_name=$(oc get bmh -n openshift-machine-api "$replaced_master_hostname" -o jsonpath={.spec.consumerRef.name})

  local infra_id=$(oc get machine -n openshift-machine-api "$replaced_machine_name" -o jsonpath={..labels."machine\.openshift\.io/cluster-api-cluster"})
  export infra_id="$infra_id"

  local new_hostname_short=$(echo "$new_master_hostname" |cut -d '.' -f 1)
  export new_machine_name="$infra_id-$new_hostname_short"
}

create_new_bmh_machine(){
  jinja2 "$BASEDIR"/templates/baremetal-host.yaml.j2 | oc apply -f -
  jinja2 "$BASEDIR"/templates/machine.yaml.j2 | oc apply -f -
}

link_machine_node(){
  "$BASEDIR"/link-machine-and-node.sh "$new_machine_name" "$new_master_hostname"
}

wait_for_shutdown(){
  # node is in ready status
  if [ "True" = $(oc get nodes "$replaced_master_hostname" -o jsonpath="{.status.conditions[?(@.type=='Ready')].status}") ]; then
    read -r -p "Please shut down the master node which is going to be replaced. continue if it's been down(y/n)?" choice
    case "$choice" in
      y|Y ) echo "yes";;
      n|N ) echo "no";;
      * ) echo "invalid";;
    esac
  fi
}

wait_etcd_operator(){
  while [ "True" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Degraded")].status}'})" ] || [ "True" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Progressing")].status}'})" ] || [ "False" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Available")].status}'})" ]; do
    sleep 10
  done
}


print_etcd_member(){
  #find a healthy one
  local etcd_pod=$(oc get pod -n openshift-etcd --selector app=etcd --field-selector status.phase=Running,metadata.name!=etcd-"$replaced_master_hostname",metadata.name!=etcd-"$new_master_hostname" -o jsonpath="{.items[0].metadata.name}")
  
  oc rsh -n openshift-etcd "$etcd_pod" etcdctl member list -w table
  #local etcd_delete_member=$(oc rsh -n openshift-etcd "$etcd_pod" etcdctl member list |grep "$replaced_master_hostname" |cut -d ',' -f 1)
  #oc rsh -n openshift-etcd "$etcd_pod" etcdctl member remove "$etcd_delete_member"
  #oc rsh -n openshift-etcd "$etcd_pod" etcdctl member list -w table
}

delete_old_bmh_machine(){
  echo "Delete old BaremetalHost and Machine."
  oc delete bmh -n openshift-machine-api "$replaced_master_hostname"
  oc delete machine -n openshift-machine-api "$replaced_machine_name"
}

monitor(){
  while [ "True" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Degraded")].status}'})" ] || [ "True" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Progressing")].status}'})" ] || [ "False" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Available")].status}'})" ]; do
    sleep 10
  done
  oc get co -w
}


export_cluster_info
create_new_bmh_machine
link_machine_node
wait_etcd_operator
print_etcd_member
wait_for_shutdown
delete_old_bmh_machine
wait_etcd_operator
print_etcd_member
monitor
print_cluster_info
