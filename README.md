# Procedures to scale an OpenShift cluster

## Ideas

Using OpenShift Multi-Cluster Engine(MCE) to expand the cluster. Either install MCE on a dedicated cluster or the target cluster which is going to expand.

## Procedures

- Setup storage solution if not already have
- Install MCE Operator and create MCE hub instance
- Import the target cluster into the MCE hub
- Add worker with MCE
- Add master with MCE and replace a broken one

### Storage

Your cluster which will be used as MCE hub should have a storage solution available. In this sample we  will use LVM Storage Operator.

```shell
oc apply -k ./lvm/operator
```

Validate if operator has been installed:

```shell
$ oc get subs,csv,ip,pod -n openshift-storage 
NAME                                              PACKAGE         SOURCE             CHANNEL
subscription.operators.coreos.com/lvms-operator   lvms-operator   redhat-operators   stable-4.12

NAME                                                               DISPLAY       VERSION   REPLACES                PHASE
clusterserviceversion.operators.coreos.com/lvms-operator.v4.12.1   LVM Storage   4.12.1    lvms-operator.v4.12.0   Succeeded

NAME                                             CSV                     APPROVAL    APPROVED
installplan.operators.coreos.com/install-mcnsz   lvms-operator.v4.12.1   Automatic   true

NAME                                READY   STATUS    RESTARTS   AGE
pod/lvms-operator-bc46d8747-vbd6t   3/3     Running   0          21s

```


Create a LVMCluster:

```shell
$ oc apply -k lvm/lvmcluster/
```

Validate:

```
$ oc get pod -n openshift-storage 
NAME                                  READY   STATUS    RESTARTS   AGE
lvms-operator-bc46d8747-vbd6t         3/3     Running   0          3m19s
topolvm-controller-5496f5d4f4-mcbzx   5/5     Running   0          2m1s
topolvm-node-5s2jx                    4/4     Running   0          2m1s
topolvm-node-6nk7p                    4/4     Running   0          2m1s
topolvm-node-bkbrm                    4/4     Running   0          2m1s
vg-manager-692sv                      1/1     Running   0          2m1s
vg-manager-ctc8q                      1/1     Running   0          2m1s
vg-manager-x88n5                      1/1     Running   0          2m1s

$ oc get lvmclusters.lvm.topolvm.io -n openshift-storage 
NAME         AGE
lvmcluster   107s
```

### Install OpenShift MCE(multiple Cluster Engine) operator

```shell
oc apply -k ./mce/operator
```

Validate if the operator has been installed successully:

```shell
$ oc get csv,subs,ip,pod -n multicluster-engine 
NAME                                                                    DISPLAY                              VERSION   REPLACES   PHASE
clusterserviceversion.operators.coreos.com/multicluster-engine.v2.3.0   multicluster engine for Kubernetes   2.3.0                Succeeded

NAME                                                    PACKAGE               SOURCE             CHANNEL
subscription.operators.coreos.com/multicluster-engine   multicluster-engine   redhat-operators   stable-2.3

NAME                                             CSV                          APPROVAL    APPROVED
installplan.operators.coreos.com/install-sv56g   multicluster-engine.v2.3.0   Automatic   true

NAME                                                READY   STATUS    RESTARTS   AGE
pod/multicluster-engine-operator-86677b548c-8mrm6   1/1     Running   0          29s
pod/multicluster-engine-operator-86677b548c-xsjwr   1/1     Running   0          29s
```

### Create MCE hub instance

```shell
oc apply -k ./mce/hub-instance
```

Validate if hub instance has been created:

```
$ oc get pod -n multicluster-engine 
NAME                                                   READY   STATUS    RESTARTS      AGE
agentinstalladmission-849799f9cc-wnv6n                 1/1     Running   0             24m
agentinstalladmission-849799f9cc-xlb27                 1/1     Running   0             24m
assisted-image-service-0                               1/1     Running   0             2m38s
assisted-service-686b96b7c-fzxbm                       2/2     Running   0             78s
cluster-curator-controller-7f59cf44c8-5fs47            1/1     Running   0             25m
cluster-curator-controller-7f59cf44c8-6lrhr            1/1     Running   0             25m
cluster-image-set-controller-657fb7d59d-mqtv8          1/1     Running   0             25m
cluster-manager-698fbff898-bg75q                       1/1     Running   0             25m
cluster-manager-698fbff898-c55rk                       1/1     Running   0             25m
cluster-manager-698fbff898-wbxdm                       1/1     Running   0             25m
cluster-proxy-7547556b6b-j22km                         1/1     Running   0             24m
cluster-proxy-7547556b6b-vvz8n                         1/1     Running   0             24m
cluster-proxy-addon-manager-7bc4585697-8pmwv           1/1     Running   0             25m
cluster-proxy-addon-manager-7bc4585697-mdxqb           1/1     Running   0             25m
cluster-proxy-addon-user-768cb57585-7njnb              2/2     Running   0             24m
cluster-proxy-addon-user-768cb57585-9ht54              2/2     Running   0             24m
clusterclaims-controller-696957f994-j8w87              2/2     Running   0             25m
clusterclaims-controller-696957f994-pkqwv              2/2     Running   0             25m
clusterlifecycle-state-metrics-v2-6c974cdb98-xj2cv     1/1     Running   2 (24m ago)   25m
console-mce-console-679f4c5649-5zb6j                   1/1     Running   0             25m
console-mce-console-679f4c5649-xhm7b                   1/1     Running   0             25m
discovery-operator-5c579b9f74-tljr7                    1/1     Running   0             25m
hive-operator-695654889d-k2lm2                         1/1     Running   0             25m
infrastructure-operator-799dddcbd6-58tjm               1/1     Running   0             25m
managedcluster-import-controller-v2-5f589b8d77-462sx   1/1     Running   0             25m
managedcluster-import-controller-v2-5f589b8d77-gkkg7   1/1     Running   0             25m
multicluster-engine-operator-86677b548c-8mrm6          1/1     Running   0             27m
multicluster-engine-operator-86677b548c-xsjwr          1/1     Running   0             27m
ocm-controller-bb7c74bf9-945fr                         1/1     Running   0             25m
ocm-controller-bb7c74bf9-vzdwb                         1/1     Running   0             25m
ocm-proxyserver-7c7db4bdc6-7zz8f                       1/1     Running   0             25m
ocm-proxyserver-7c7db4bdc6-z4rlz                       1/1     Running   0             25m
ocm-webhook-d769bcf9c-7mwln                            1/1     Running   0             25m
ocm-webhook-d769bcf9c-pjtwt                            1/1     Running   0             25m
provider-credential-controller-7b7766c9c7-j5gsz        2/2     Running   0             25m

$ oc get MultiClusterEngine
NAME                 STATUS      AGE
multiclusterengine   Available   109s

```
### Import the cluster into CIM/MCE

```shell

$ cd import
$ ./import.sh 
Usage: ./import.sh [hub cluster kubeconfig] [spoke cluster kubeconfig] [admin of spoke cluster] [password of spoke cluster]
Example: ./import.sh kubeconfig-hub.yaml kubeconfig-spoke.yaml kubeadmin A5tmu-sy4GG-yeajX-TgfVr

```

An example:

```shell
$ ./import.sh kubeconfig-compact.yaml kubeconfig-compact.yaml kubeadmin SEZhw-i7XZ7-LvSIG-XGTR6
namespace/compact created
secret/compact-admin-kubeconfig created
secret/compact-admin-password created
secret/pull-secret created
infraenv.agent-install.openshift.io/compact created
managedcluster.cluster.open-cluster-management.io/compact created
agentclusterinstall.extensions.hive.openshift.io/compact created
clusterdeployment.hive.openshift.io/compact created

```

Validate if the cluster has been imported:

```shell
$ oc get mcl
NAME            HUB ACCEPTED   MANAGED CLUSTER URLS                            JOINED   AVAILABLE   AGE
compact         true           https://api.compact.outbound.vz.bos2.lab:6443   True     True        6m19s
local-cluster   true           https://api.compact.outbound.vz.bos2.lab:6443   True     True        57m

```

### Add worker node 

TODO

###  Replace a master node

TODO