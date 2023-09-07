```shell
[root@hub-helper cleanup]# ./clean.sh 
You are going to detach the managed cluster compact from the MCE hub.

Deleting managed cluster: compact
namespace "compact" deleted
secret "compact-admin-kubeconfig" deleted
secret "pull-secret" deleted
infraenv.agent-install.openshift.io "compact" deleted
managedcluster.cluster.open-cluster-management.io "compact" deleted
agentclusterinstall.extensions.hive.openshift.io "compact" deleted
clusterdeployment.hive.openshift.io "compact" deleted

Deleting MultiClusterEngine instance.
agentserviceconfig.agent-install.openshift.io "agent" deleted
multiclusterengine.multicluster.openshift.io "multiclusterengine" deleted

Deleting MultiClusterEngine operator.
installplan.operators.coreos.com "install-wm2k4" deleted
clusterserviceversion.operators.coreos.com "multicluster-engine.v2.3.1" deleted
subscription.operators.coreos.com "multicluster-engine" deleted
operatorgroup.operators.coreos.com "multicluster-engine" deleted

namespace "multicluster-engine" deleted

Done

```