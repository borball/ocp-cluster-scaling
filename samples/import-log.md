```shell
[root@hub-helper ocp-cluster-scale-local]# cd import/

[root@hub-helper import]# ./import.sh
namespace/compact created
secret/compact-admin-kubeconfig created
secret/pull-secret created
infraenv.agent-install.openshift.io/compact created
managedcluster.cluster.open-cluster-management.io/compact created
agentclusterinstall.extensions.hive.openshift.io/compact created
clusterdeployment.hive.openshift.io/compact created

[root@hub-helper import]# oc get mcl
NAME      HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
compact   true                                                       5s

[root@hub-helper import]# oc get mcl
NAME      HUB ACCEPTED   MANAGED CLUSTER URLS                            JOINED   AVAILABLE   AGE
compact   true           https://api.compact.outbound.vz.bos2.lab:6443   True     True        37s

```
