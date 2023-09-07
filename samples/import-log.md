```shell
[root@hub-helper import]# ./import.sh 
Will create CRs below, check the files to get more information.
total 48
-rw-r--r--. 1 root root  1057 Sep  7 19:31 agent-cluster-install.yaml
-rw-r--r--. 1 root root   695 Sep  7 19:31 cluster-deployment.yaml
-rw-r--r--. 1 root root   951 Sep  7 19:31 infraenv.yaml
-rw-r--r--. 1 root root 14406 Sep  7 19:31 kubeconfig-secret.yaml
-rw-r--r--. 1 root root   276 Sep  7 19:31 kustomization.yaml
-rw-r--r--. 1 root root   128 Sep  7 19:31 managed-cluster.yaml
-rw-r--r--. 1 root root    57 Sep  7 19:31 ns.yaml
-rw-r--r--. 1 root root  4276 Sep  7 19:31 pull-secret.yaml
namespace/compact created
secret/compact-admin-kubeconfig created
secret/pull-secret created
infraenv.agent-install.openshift.io/compact created
managedcluster.cluster.open-cluster-management.io/compact created
agentclusterinstall.extensions.hive.openshift.io/compact created
clusterdeployment.hive.openshift.io/compact created

NAME      HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
compact   true                                                       0s

Run oc get mcl -w to monitor that if the cluster will be imported properly.

```
