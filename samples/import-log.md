```shell
[root@hub-helper ocp-cluster-scale-local]# cd import/

[root@hub-helper import]# ./import.sh /root/workload-enablement/kubeconfigs/kubeconfig-mce.yaml /root/workload-enablement/kubeconfigs/kubeconfig-compact.yaml 
Will create CRs below, check the files to get more information.
-rw-r--r--. 1 root root  1057 Aug 30 21:13 /root/ocp-cluster-scaling-master/import/agent-cluster-install.yaml
-rw-r--r--. 1 root root   695 Aug 30 21:13 /root/ocp-cluster-scaling-master/import/cluster-deployment.yaml
-rw-r--r--. 1 root root   951 Aug 30 21:13 /root/ocp-cluster-scaling-master/import/infraenv.yaml
-rw-r--r--. 1 root root 14414 Aug 30 21:13 /root/ocp-cluster-scaling-master/import/kubeconfig-secret.yaml
-rw-r--r--. 1 root root   276 Aug 30 20:09 /root/ocp-cluster-scaling-master/import/kustomization.yaml
-rw-r--r--. 1 root root   128 Aug 30 21:13 /root/ocp-cluster-scaling-master/import/managed-cluster.yaml
-rw-r--r--. 1 root root    57 Aug 30 21:13 /root/ocp-cluster-scaling-master/import/ns.yaml
-rw-r--r--. 1 root root  4276 Aug 30 21:13 /root/ocp-cluster-scaling-master/import/pull-secret.yaml
namespace/compact created
secret/compact-admin-kubeconfig created
secret/pull-secret created
infraenv.agent-install.openshift.io/compact created
managedcluster.cluster.open-cluster-management.io/compact created
agentclusterinstall.extensions.hive.openshift.io/compact created
clusterdeployment.hive.openshift.io/compact created

[root@hub-helper import]# # oc get mcl
NAME      HUB ACCEPTED   MANAGED CLUSTER URLS                            JOINED   AVAILABLE   AGE
compact   true           https://api.compact.outbound.vz.bos2.lab:6443   True     True        5m

```
