```shell
[root@hub-helper scale]# ./delete-worker.sh worker0.compact.outbound.vz.bos2.lab 
Cluster nodes:
NAME                                   STATUS   ROLES                         AGE     VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   6h34m   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   6h51m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   6h50m   v1.25.11+1485cc9
master3.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   4h47m   v1.25.11+1485cc9
worker0.compact.outbound.vz.bos2.lab   Ready    worker                        5h47m   v1.25.11+1485cc9

Deleting agent 22222222-1111-1111-0000-000000000010
agent.agent-install.openshift.io "22222222-1111-1111-0000-000000000010" deleted
Deleting node worker0.compact.outbound.vz.bos2.lab
node "worker0.compact.outbound.vz.bos2.lab" deleted
Cluster nodes:
NAME                                   STATUS   ROLES                         AGE     VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   6h34m   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   6h51m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   6h50m   v1.25.11+1485cc9
master3.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   4h47m   v1.25.11+1485cc9


*********************************
Although the node object is now deleted from the cluster, it can still rejoin the cluster after reboot or if the kubelet service is restarted.
To permanently delete the node and all its data, you must decommission the node.
Reference: https://docs.openshift.com/container-platform/4.12/nodes/nodes/nodes-nodes-working.html#deleting-nodes

```