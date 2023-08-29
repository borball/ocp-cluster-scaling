# Procedures to scale an OpenShift cluster

## Ideas

Using OpenShift Multi-Cluster Engine(MCE) to expand the cluster. 

There are two different scenarios:

- Shared MCE hub
- Local cluster as MCE hub

### Shared MCE hub

If your lab already have many clusters deployed with different methods, but the clusters are not managed 
by Red Hat Advanced Cluster Management(ACM) or MCE(part of Red Hat ACM), you can use the helper scripts in this repo
to create an MCE hub, import the clusters into the MCE hub, manage the clusters going forward. The MCE hub can be reused 
across the different cluster, it is a 'Shared MCE hub'. The cluster which acts as the 'Shared MCE hub' is a 'Management Cluster'.
The clusters imported into the MCE hub are 'Managed Clusters'.

### Local cluster as MCE hub

If you only want to expand one particular cluster, you can use the helper scripts in this repo
to create an MCE hub on the cluster itself(local-cluster), import the cluster into the MCE hub and expand it.

This [local-cluster](https://github.com/borball/ocp-cluster-scaling/tree/local-cluster) branch is a simplified version for this scenario. 

## Procedures

- Setup storage solution if not already have
- Install MCE Operator and create MCE hub instance
- Import the cluster into the MCE hub
- Add worker with MCE
- Add master with MCE and replace a broken(or healthy) one

### Storage

Your cluster should have a storage solution available. Please ignore this step if you already have.
In this example we will use LVM Storage Operator.

```shell
oc apply -k ./lvm/operator
```

Validate if operator has been installed:

```shell
oc get subs,csv,ip,pod -n openshift-storage 
```
Example:
```sh
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
oc apply -k lvm/lvmcluster/
```

Validate:

```shell
oc get pod -n openshift-storage
oc get lvmclusters.lvm.topolvm.io -n openshift-storage 
```

Example:
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

### Install OpenShift MCE(Multi-Cluster Engine) operator

```shell
oc apply -k ./mce/operator
```

Validate if the operator has been installed successfully:

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

Validate if hub instance has been created, a sample on a compact cluster(3-master cluster):

```shell
oc get pod -n multicluster-engine 
oc get MultiClusterEngine
```

Example:
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
### Import the cluster into MCE hub

```shell

cd import
./import.sh kubeconfig-hub.yaml kubeconfig-spoke.yaml
```

An example:

```shell
$ ./import.sh kubeconfig-hub.yaml kubeconfig-spoke.yaml
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

On the hub cluster:
```shell
oc get mcl
```

Example:
```shell
oc get mcl
NAME            HUB ACCEPTED   MANAGED CLUSTER URLS                            JOINED   AVAILABLE   AGE
compact         true           https://api.compact.outbound.vz.bos2.lab:6443   True     True        6m19s
```

### Add a node

Prepare a config file such as config-worker0.yaml, following is an example:

```yaml
#MCE hub kubeconfig
hub:
  kubeconfig: kubeconfig-hub.yaml

#The cluster which will be imported
managed:
  kubeconfig: kubeconfig-managed.yaml

#new node information
node:
  hostname: worker0.compact.outbound.vz.bos2.lab
  #worker or master
  role: worker
  #disk is optional
  disk: /dev/sda

  bmc:
    address: 192.168.58.15:8080
    username: Administrator
    password: dummy
    #kvm_uuid is for KVM simulated with Sushy-tools only
    kvm_uuid: 22222222-1111-1111-0000-000000000010

  #network is not necessary if dhcp is being used, or a NMStateConfig CR is explicitly specified
  network:
    dns:
      - 192.168.58.15
      #- 2600:52:7:58::15
    interface: ens1f0
    mac: de:ad:be:ff:10:40
    ipv4:
      enabled: true
      ip: 192.168.58.40
      prefix: 25
      gateway: 192.168.58.1
    ipv6:
      enabled: false
      ip: 2600:52:7:58::40
      prefix: 64
      gateway: 2600:52:7:58::1
    vlan:
      enabled: false
      id: 58
      name: ens1f0.58

```

You can set the node.role as 'worker' if the new node is a worker. set it as 'master' if the new node is a master.

If the new node network is simple enough like DHCP or static IPv4/Ipv6 with/without vLan, you can simply set the network information inside the config.yaml under node.network, a NMStateConfig will be created automatically based on a default template inside [nmstate.yaml.j2](./scale/templates/nmstate.yaml.j2).

If the default template cannot meet your lab situation, a NMStateConfig CR such as nm-state-worker0.yaml shall be prepared, reference of: [NMStateConfig CRD](https://github.com/openshift/assisted-service/blob/master/config/crd/bases/agent-install.openshift.io_nmstateconfigs.yaml).

Next we will add the node into the cluster.

```shell
cd scale
```

```shell
./add-node.sh config-worker0.yaml
```
Or:

```shell
./add-node.sh config-worker0.yaml nm-state-worker0.yaml
```

What the script does:

- Creating NMStateConfig CR based on the nm-state.yaml file specified in the command line or the built-in NMStateConfig template if node.network is present in the config.yaml.
- Mount the discovery ISO hosted by Assisted Service as a Virtual Media on the BMC console.
- Boot the node from the discovery ISO.
- Patching the Agent CR to set the role of the new node as the node.role defined in the config.yaml.
- Approving the node to be added in the InfraEnv of the cluster.
- Adding the node as a new host in the cluster.
- Linking the Agent CR to the cluster’s ClusterDeployment CR to trigger the new node installation.
- Monitoring the installation progress.

Following is some execution logs

- [Add a new worker](samples/new-worker.md)
- [Add a new master](samples/new-master.md)
- [Add a new master with nm-state](samples/new-master-nmstate.md)

###  Replace a master node

Follow the steps above to add a new master node into the cluster.

Next we will replace the existing master node with the new added one.

```shell
./replace-master.sh old-master-node new-master-node
```

What the script does are:

- Adding BaremetalHost CR and Machine CR for the new master node and linking them with each other.
- Deleting the existing BaremetalHost CR and Machine CR.
- Monitoring OpenShift to roll out the cluster operators and platform components to the new node.
