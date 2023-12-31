#!/bin/bash
#
# - Replace a master with the new added one
#

set -euo pipefail

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
export BASEDIR=$BASEDIR

usage(){
  echo "Usage: $0 old-master new-master"
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

old_master_node=$1
new_master_node=$2

pre_check(){
  echo "-------------------------------"
  if oc get node "$old_master_node" 1>/dev/null; then
    echo "Node $old_master_node exist will be replaced."
  else
    echo "Node $old_master_node not exist."
    exit 1
  fi

  if oc get node "$new_master_node" 1>/dev/null; then
    echo "Node $new_master_node will be the new master."
  else
    echo "Node $new_master_node not exist."
    exit 1
  fi
}

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
  export new_master_node
  boot_mode=$(oc get bmh -n openshift-machine-api "$old_master_node" -o jsonpath={.spec.bootMode})
  export boot_mode

  local old_machine_name=$(oc get bmh -n openshift-machine-api "$old_master_node" -o jsonpath={.spec.consumerRef.name})

  infra_id=$(oc get machine -n openshift-machine-api "$old_machine_name" -o jsonpath={..labels."machine\.openshift\.io/cluster-api-cluster"})
  export infra_id

  local new_hostname_short=$(echo "$new_master_node" |cut -d '.' -f 1)
  export new_machine_name="$infra_id-$new_hostname_short"
}

create_new_bmh_machine(){
  echo "-------------------------------"
  echo "Create BaremetalHost and Machine for the new master."
  jinja2 "$BASEDIR"/templates/baremetal-host.yaml.j2 | oc apply -f -
  jinja2 "$BASEDIR"/templates/machine.yaml.j2 | oc apply -f -
  sleep 30
}

link_machine_node(){
  echo "-------------------------------"
  echo "Link the new created BaremetalHost and Machine."
  "$BASEDIR"/link-machine-and-node.sh "$new_machine_name" "$new_master_node"
}

wait_for_shutdown(){
  #If old node is in ready status
  if [ "True" = $(oc get nodes "$old_master_node" -o jsonpath="{.status.conditions[?(@.type=='Ready')].status}") ]; then
    read -r -p "Please shut down the master node which is going to be replaced. continue if it's been down(y/n)?" choice
    case "$choice" in
      y|Y ) echo "yes";;
      n|N ) echo "no";;
      * ) echo "invalid";;
    esac
  fi
}

wait_etcd_operator(){
  echo "-------------------------------"
  while [ "True" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Degraded")].status}'})" ] || [ "True" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Progressing")].status}'})" ] || [ "False" = "$(oc get co etcd -o jsonpath='{..conditions[?(@.type=="Available")].status}'})" ]; do
    sleep 10
  done
}

find_healthy_etcd_pod(){
  export etcd_pod=$(oc get pod -n openshift-etcd --selector app=etcd --field-selector status.phase=Running,metadata.name!=etcd-"$old_master_node",metadata.name!=etcd-"$new_master_node" -o jsonpath="{.items[0].metadata.name}")
}

print_etcd_member(){
  echo "-------------------------------"
  echo "ETCD member list:"
  oc rsh -n openshift-etcd "$etcd_etcd_podpod" etcdctl member list -w table
}

delete_etcd_member(){
  echo "-------------------------------"
  echo "Delete ETCD member "$old_master_node":"
  local etcd_delete_member=$(oc rsh -n openshift-etcd "$etcd_pod" etcdctl member list |grep "$old_master_node" |cut -d ',' -f 1)
  oc rsh -n openshift-etcd "$etcd_pod" etcdctl member remove "$etcd_delete_member"
}

delete_old_bmh_machine(){
  echo "-------------------------------"
  echo "Delete old BaremetalHost and Machine."
  local old_machine_name=$(oc get bmh -n openshift-machine-api "$old_master_node" -o jsonpath={.spec.consumerRef.name})
  oc delete bmh -n openshift-machine-api "$old_master_node"
  oc delete machine -n openshift-machine-api "$old_machine_name"
}

last_check(){
  oc get nodes
  oc get co

  echo "The master node has been replaced, but it may take time to roll out all cluster operators to the new node."
  echo "Please run oc get co -w to monitor if all cluster operators are available and not downgraded."
}

pre_check
export_cluster_info
create_new_bmh_machine
link_machine_node
find_healthy_etcd_pod
wait_etcd_operator
print_etcd_member
wait_for_shutdown
delete_old_bmh_machine
delete_etcd_member
sleep 60
wait_etcd_operator
print_etcd_member
last_check