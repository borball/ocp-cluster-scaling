# Procedures to scale an OpenShift cluster

## Ideas

Using OpenShift Multi-Cluster Engine(MCE) to expand the cluster. Either install MCE on a dedicated cluster or the target cluster which is going to expand.

## Procedures

- Setup storage solution if not already have
- Install MCE Operator and create MCE hub instance
- Import the target cluster into the MCE hub
- Add worker with MCE
- Add master with MCE and replace a broken(or healthy) one

### Storage

Your cluster which will be used as MCE hub should have a storage solution available. Please ignore this step if you alreadh have. 

In this sample we  will use LVM Storage Operator.

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

### Install OpenShift MCE(Multi-Cluster Engine) operator

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

Validate if hub instance has been created, a sample on a compact cluster(3-master cluster):

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
### Import the cluster which is going to scale into MCE hub

```shell

$ cd import
$ ./import.sh 
Usage: ./import.sh [hub-cluster-kubeconfig] [spoke-cluster-kubeconfig] [spoke-cluster-admin] [spoke-cluster-password]
If the hub-cluster-kubeconfig equals to spoke-cluster-kubeconfig, it means it is going to expand the cluster itself.
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
```

### Discovery ISO

Download the discovery ISO which can be used as virtual media to boot the node and start the OCP installation.

```shell
$ cd scale
./download-iso.sh <hub-kubeconfig> <cluster-name>
```

The ISO file will be saved as discovery.iso in the current folder, you can transfer it to your HTTP server so that the new nodes can mount it as a virtual medai and boot the nodes from there.

### Add worker node 

Prepare a config file like config-worker.yaml, following is an example:

```yaml
#kueconfig location of MCE hub instance
hub:
  kubeconfig: ./kubeconfig-compact.yaml

#name of the cluster which is going to expand
cluster:
  name: compact
  kubeconfig: ./kubeconfig-compact.yaml

#where the discovery iso located, this will be mounted on the BMC of the additional worker node to do the installation
iso:
  address: http://192.168.58.15/iso/compact-discovery.iso

#worker node information
worker:
  ## it won't create nmstateconfig if dhcp is true
  dhcp: false
  hostname: worker1.compact.outbound.vz.bos2.lab
  dns:
    - 192.168.58.15
    #- 2600:52:7:58::15
  interface: ens1f0
  #boot mac address
  mac: de:ad:be:ff:10:33
  ipv4:
    enabled: true
    ip: 192.168.58.33
    prefix: 25
    gateway: 192.168.58.1
  ipv6:
    enabled: false
    ip: 2600:52:7:58::58
    prefix: 64
    gateway: 2600:52:7:58::1
  vlan:
    enabled: false
    id: 58
    name: ens1f0.58    
  #bmc info of worker node
  bmc:
    address: 192.168.58.15:8080
    username: Administrator
    password: dummy
    #optional, specify it if sushy-tools is being used as BMC emulator
    kvm_uuid: 22222222-1111-1111-0000-000000000003

```

The hub.kubeconfig and cluster.kubeconfig can be the different if you are using another dedicated cluster to expand other clusters.

Next we will add the worker into the cluster

```shell
$ cd worker
$ ./add.sh config-compact.yaml   
```

What the script does are:

- Creating nmstateconfig CR for the new worker node if advanced network setting is being used.
- Booting the node from the ISO location indicated in the configuration file.
- Patching the Agent CR to set the role of the new node as ‘worker’.
- Approving the node to be added in the InfraEnv of the cluster.
- Adding the node as a new host in the cluster.
- Linking the Agent CR to the cluster’s ClusterDeployment CR to trigger the new node installation.
- Monitoring the installation progress.

Following is an execution sample:
 
```shell
# ./add.sh config-add-worker0.yaml 
Current cluster information

NAME                                   STATUS   ROLES                         AGE   VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   65m   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   83m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   85m   v1.25.11+1485cc9

NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.27   True        False         54m     Cluster version is 4.12.27

New worker node uses static IP, will create NMStateConfig CR
---
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  labels:
    infraenvs.agent-install.openshift.io: compact
  name: worker0.compact.outbound.vz.bos2.lab
  namespace: compact
spec:
  interfaces:
  - macAddress: de:ad:be:ff:10:40
    name: ens1f0

  config:
    dns-resolver:
      config:
        server:
        - 192.168.58.15
        
    interfaces:
    - name: ens1f0
      type: ethernet
      state: up
      mac-address: de:ad:be:ff:10:40
      ipv4:
        address:
        - ip: 192.168.58.40
          prefix-length: 25
        enabled: true
        dhcp: false
      
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.58.1
        next-hop-interface: ens1f0
      

nmstateconfig.agent-install.openshift.io/worker0.compact.outbound.vz.bos2.lab created

-------------------------------
Power off server.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000010/Actions/ComputerSystem.Reset
-------------------------------

204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia
-------------------------------

Insert Virtual Media: http://192.168.58.15/iso/compact-discovery.iso
204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia
-------------------------------

Virtual Media Status: 
{
  "@odata.type": "#VirtualMedia.v1_4_0.VirtualMedia",
  "Id": "Cd",
  "Name": "Virtual CD",
  "MediaTypes": [
    "CD",
    "DVD"
  ],
  "Image": "compact-discovery.iso",
  "ImageName": "",
  "ConnectedVia": "URI",
  "Inserted": true,
  "WriteProtected": true,
  "Actions": {
    "#VirtualMedia.EjectMedia": {
      "target": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia"
    },
    "#VirtualMedia.InsertMedia": {
      "target": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia"
    },
    "Oem": {}
  },
  "UserName": "",
  "Password": "",
  "Certificates": {
    "@odata.id": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd/Certificates"
  },
  "VerifyCertificate": false,
  "@odata.context": "/redfish/v1/$metadata#VirtualMedia.VirtualMedia",
  "@odata.id": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd",
  "@Redfish.Copyright": "Copyright 2014-2017 Distributed Management Task Force, Inc. (DMTF). For the full DMTF copyright policy, see http://www.dmtf.org/about/policies/copyright."
}
-------------------------------

Boot node from Virtual Media Once
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000010
-------------------------------

Power on server.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000010/Actions/ComputerSystem.Reset

-------------------------------
Node is booting from virtual media mounted with http://192.168.58.15/iso/compact-discovery.iso, check your BMC console to monitor the progress.


Node booting.

No resources found in compact namespace.
No resources found in compact namespace.
No resources found in compact namespace.
No resources found in compact namespace.
No resources found in compact namespace.
22222222-1111-1111-0000-000000000010             false      auto-assign   
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
-------------------------------
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed 33/100
Installation in progress: completed 33/100
Installation in progress: completed 33/100
Installation in progress: completed 33/100
Installation in progress: completed 33/100
Installation in progress: completed 55/100
Installation in progress: completed 88/100
Installation in progress: completed 88/100
Installation in progress: completed 88/100
Installation completed.

NAME                                   STATUS   ROLES                         AGE    VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   124m   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   144m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   143m   v1.25.11+1485cc9
worker0.compact.outbound.vz.bos2.lab   Ready    worker                        83s    v1.25.11+1485cc9

```

###  Replace a master node

Prepare a config file like config-master.yaml, following is an example:

```yaml
#kueconfig location of MCE hub instance
hub:
  kubeconfig: ./kubeconfig-compact.yaml

#name of the cluster which is going to expand
cluster:
  name: compact
  kubeconfig: ./kubeconfig-compact.yaml

#where the discovery iso located, this will be mounted on the BMC of the additional worker node to do the installation
iso:
  address: http://192.168.58.15/iso/compact-discovery.iso

#master node information
master:
  replaced: master0.compact.outbound.vz.bos2.lab
  #it won't create nmstateconfig if dhcp is true
  dhcp: false
  hostname: master3.compact.outbound.vz.bos2.lab
  dns:
    - 192.168.58.15
    #- 2600:52:7:58::15
  interface: ens1f0
  mac: de:ad:be:ff:10:33
  ipv4:
    enabled: true
    ip: 192.168.58.33
    prefix: 25
    gateway: 192.168.58.1
  ipv6:
    enabled: false
    ip: 2600:52:7:58::33
    prefix: 64
    gateway: 2600:52:7:58::1
  vlan:
    enabled: false
    id: 58
    name: ens1f0.58    
  bmc:
    address: 192.168.58.15:8080
    username: Administrator
    password: dummy
    #Optinal, required only when the node is a KVM instance
    kvm_uuid: 22222222-1111-1111-0000-000000000003
```

The hub.kubeconfig and cluster.kubeconfig can be the different if you are using another dedicated cluster to expand other clusters.

Next we will add a new master node into the cluster and replace the existing one.

```shell
$ cd master
$ ./add.sh <config-file>
```

What the script does are:

- Creating nmstateconfig CR for the new master node if advanced network setting is being used.
- Booting the node from the ISO location indicated in the configuration file.
- Patching the Agent CR to set the role of the new node as ‘master’.
- Approving the node to be added in the InfraEnv of the cluster.
- Adding the node as a new host in the cluster.
- Linking the Agent CR to the cluster’s ClusterDeployment CR to trigger the new node installation.
- Monitoring the installation progress.
- Adding BaremetalHost CR and Machine CR for the new master node and linking them with each other.
- Removing the existing node from the ETCD member list.
- Deleting the existing BaremetalHost CR and Machine CR.
- Monitoring OpenShift to roll out the cluster operators and platform components to the new node.


Following is an execution sample:

```shell
# ./add.sh config-master0-replaced-by-master3.yaml 
Current cluster information

NAME                                   STATUS   ROLES                         AGE    VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   99m    v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   117m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   118m   v1.25.11+1485cc9
worker0.compact.outbound.vz.bos2.lab   Ready    worker                        16m    v1.25.11+1485cc9

NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.27   True        False         88m     Cluster version is 4.12.27

New master node uses static IP, will create NMStateConfig CR
---
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  labels:
    infraenvs.agent-install.openshift.io: compact
  name: master3.compact.outbound.vz.bos2.lab
  namespace: compact
spec:
  interfaces:
  - macAddress: de:ad:be:ff:10:33
    name: ens1f0

  config:
    dns-resolver:
      config:
        server:
        - 192.168.58.15
        
    interfaces:
    - name: ens1f0
      type: ethernet
      state: up
      mac-address: de:ad:be:ff:10:33
      ipv4:
        address:
        - ip: 192.168.58.33
          prefix-length: 25
        enabled: true
        dhcp: false
      
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.58.1
        next-hop-interface: ens1f0
      

nmstateconfig.agent-install.openshift.io/master3.compact.outbound.vz.bos2.lab created
-------------------------------
Power off server.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000003/Actions/ComputerSystem.Reset
-------------------------------

204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia
-------------------------------

Insert Virtual Media: http://192.168.58.15/iso/compact-discovery.iso
204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia
-------------------------------

Virtual Media Status: 
{
  "@odata.type": "#VirtualMedia.v1_4_0.VirtualMedia",
  "Id": "Cd",
  "Name": "Virtual CD",
  "MediaTypes": [
    "CD",
    "DVD"
  ],
  "Image": "compact-discovery.iso",
  "ImageName": "",
  "ConnectedVia": "URI",
  "Inserted": true,
  "WriteProtected": true,
  "Actions": {
    "#VirtualMedia.EjectMedia": {
      "target": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia"
    },
    "#VirtualMedia.InsertMedia": {
      "target": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia"
    },
    "Oem": {}
  },
  "UserName": "",
  "Password": "",
  "Certificates": {
    "@odata.id": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Certificates"
  },
  "VerifyCertificate": false,
  "@odata.context": "/redfish/v1/$metadata#VirtualMedia.VirtualMedia",
  "@odata.id": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd",
  "@Redfish.Copyright": "Copyright 2014-2017 Distributed Management Task Force, Inc. (DMTF). For the full DMTF copyright policy, see http://www.dmtf.org/about/policies/copyright."
}
-------------------------------

Boot node from Virtual Media Once
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000003
-------------------------------

Power on server.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000003/Actions/ComputerSystem.Reset

-------------------------------
Node is booting from virtual media mounted with http://192.168.58.15/iso/compact-discovery.iso, check your BMC console to monitor the progress.


Node booting.

22222222-1111-1111-0000-000000000003             false      auto-assign   
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
-------------------------------
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed 42/100
Installation in progress: completed 42/100
Installation in progress: completed 42/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 85/100
Installation in progress: completed 85/100
Installation in progress: completed 85/100
Installation in progress: completed 85/100
Installation completed.

Afet adding the node:
NAME                                   STATUS   ROLES                         AGE    VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   112m   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   130m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   131m   v1.25.11+1485cc9
master3.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   81s    v1.25.11+1485cc9
worker0.compact.outbound.vz.bos2.lab   Ready    worker                        29m    v1.25.11+1485cc9

baremetalhost.metal3.io/master3.compact.outbound.vz.bos2.lab created
machine.machine.openshift.io/compact-7tj89-master3 created
Waiting for oc_proxy to respond Success!
Starting to serve on 127.0.0.1:8001
PATCHING HOST
{
  "status": {
    "hardware": {
      "hostname": "master3.compact.outbound.vz.bos2.lab",
      "nics": [
        {
          "ip": "192.168.58.33",
          "mac": "00:00:00:00:00:00",
          "model": "unknown",
          "speedGbps": 10,
          "vlanId": 0,
          "pxe": true,
          "name": "eth1"
        }
      ],
      "systemVendor": {
        "manufacturer": "Red Hat",
        "productName": "product name",
        "serialNumber": ""
      },
      "firmware": {
        "bios": {
          "date": "04/01/2014",
          "vendor": "SeaBIOS",
          "version": "1.11.0-2.el7"
        }
      },
      "ramMebibytes": 0,
      "storage": [],
      "cpu": {
        "arch": "x86_64",
        "model": "Intel(R) Xeon(R) CPU E5-2630 v4 @ 2.20GHz",
        "clockMegahertz": 2199.998,
        "count": 4,
        "flags": []
      }
    }
  }
}
{
  "apiVersion": "metal3.io/v1alpha1",
  "kind": "BareMetalHost",
  "metadata": {
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"metal3.io/v1alpha1\",\"kind\":\"BareMetalHost\",\"metadata\":{\"annotations\":{},\"name\":\"master3.compact.outbound.vz.bos2.lab\",\"namespace\":\"openshift-machine-api\"},\"spec\":{\"automatedCleaningMode\":\"metadata\",\"bmc\":{\"address\":\"\",\"credentialsName\":\"\"},\"bootMACAddress\":\"de:ad:be:ff:10:33\",\"bootMode\":\"legacy\",\"consumerRef\":{\"apiVersion\":\"machine.openshift.io/v1beta1\",\"kind\":\"Machine\",\"name\":\"compact-7tj89-master3\",\"namespace\":\"openshift-machine-api\"},\"customDeploy\":{\"method\":\"install_coreos\"},\"externallyProvisioned\":true,\"hardwareProfile\":\"unknown\",\"online\":true,\"userData\":{\"name\":\"master-user-data-managed\",\"namespace\":\"openshift-machine-api\"}}}\n"
    },
    "creationTimestamp": "2023-08-10T21:32:43Z",
    "finalizers": [
      "baremetalhost.metal3.io"
    ],
    "generation": 1,
    "managedFields": [
      {
        "apiVersion": "metal3.io/v1alpha1",
        "fieldsType": "FieldsV1",
        "fieldsV1": {
          "f:metadata": {
            "f:annotations": {
              ".": {},
              "f:kubectl.kubernetes.io/last-applied-configuration": {}
            }
          },
          "f:spec": {
            ".": {},
            "f:automatedCleaningMode": {},
            "f:bmc": {
              ".": {},
              "f:address": {},
              "f:credentialsName": {}
            },
            "f:bootMACAddress": {},
            "f:bootMode": {},
            "f:consumerRef": {},
            "f:customDeploy": {
              ".": {},
              "f:method": {}
            },
            "f:externallyProvisioned": {},
            "f:hardwareProfile": {},
            "f:online": {},
            "f:userData": {}
          }
        },
        "manager": "kubectl-client-side-apply",
        "operation": "Update",
        "time": "2023-08-10T21:32:43Z"
      },
      {
        "apiVersion": "metal3.io/v1alpha1",
        "fieldsType": "FieldsV1",
        "fieldsV1": {
          "f:metadata": {
            "f:finalizers": {
              ".": {},
              "v:\"baremetalhost.metal3.io\"": {}
            }
          }
        },
        "manager": "baremetal-operator",
        "operation": "Update",
        "time": "2023-08-10T21:32:44Z"
      },
      {
        "apiVersion": "metal3.io/v1alpha1",
        "fieldsType": "FieldsV1",
        "fieldsV1": {
          "f:status": {
            ".": {},
            "f:errorCount": {},
            "f:errorMessage": {},
            "f:goodCredentials": {},
            "f:hardwareProfile": {},
            "f:lastUpdated": {},
            "f:operationHistory": {
              ".": {},
              "f:deprovision": {
                ".": {},
                "f:end": {},
                "f:start": {}
              },
              "f:inspect": {
                ".": {},
                "f:end": {},
                "f:start": {}
              },
              "f:provision": {
                ".": {},
                "f:end": {},
                "f:start": {}
              },
              "f:register": {
                ".": {},
                "f:end": {},
                "f:start": {}
              }
            },
            "f:operationalStatus": {},
            "f:poweredOn": {},
            "f:provisioning": {
              ".": {},
              "f:ID": {},
              "f:image": {
                ".": {},
                "f:url": {}
              },
              "f:state": {}
            },
            "f:triedCredentials": {}
          }
        },
        "manager": "baremetal-operator",
        "operation": "Update",
        "subresource": "status",
        "time": "2023-08-10T21:32:44Z"
      },
      {
        "apiVersion": "metal3.io/v1alpha1",
        "fieldsType": "FieldsV1",
        "fieldsV1": {
          "f:status": {
            "f:hardware": {
              ".": {},
              "f:cpu": {
                ".": {},
                "f:arch": {},
                "f:clockMegahertz": {},
                "f:count": {},
                "f:flags": {},
                "f:model": {}
              },
              "f:firmware": {
                ".": {},
                "f:bios": {
                  ".": {},
                  "f:date": {},
                  "f:vendor": {},
                  "f:version": {}
                }
              },
              "f:hostname": {},
              "f:nics": {},
              "f:ramMebibytes": {},
              "f:storage": {},
              "f:systemVendor": {
                ".": {},
                "f:manufacturer": {},
                "f:productName": {},
                "f:serialNumber": {}
              }
            }
          }
        },
        "manager": "curl",
        "operation": "Update",
        "subresource": "status",
        "time": "2023-08-10T21:32:44Z"
      }
    ],
    "name": "master3.compact.outbound.vz.bos2.lab",
    "namespace": "openshift-machine-api",
    "resourceVersion": "85974",
    "uid": "7059dfed-34d7-4dbb-a293-fb4a99b552f6"
  },
  "spec": {
    "automatedCleaningMode": "metadata",
    "bmc": {
      "address": "",
      "credentialsName": ""
    },
    "bootMACAddress": "de:ad:be:ff:10:33",
    "bootMode": "legacy",
    "consumerRef": {
      "apiVersion": "machine.openshift.io/v1beta1",
      "kind": "Machine",
      "name": "compact-7tj89-master3",
      "namespace": "openshift-machine-api"
    },
    "customDeploy": {
      "method": "install_coreos"
    },
    "externallyProvisioned": true,
    "hardwareProfile": "unknown",
    "online": true,
    "userData": {
      "name": "master-user-data-managed",
      "namespace": "openshift-machine-api"
    }
  },
  "status": {
    "errorCount": 0,
    "errorMessage": "",
    "goodCredentials": {},
    "hardware": {
      "cpu": {
        "arch": "x86_64",
        "clockMegahertz": 2199.998,
        "count": 4,
        "flags": [],
        "model": "Intel(R) Xeon(R) CPU E5-2630 v4 @ 2.20GHz"
      },
      "firmware": {
        "bios": {
          "date": "04/01/2014",
          "vendor": "SeaBIOS",
          "version": "1.11.0-2.el7"
        }
      },
      "hostname": "master3.compact.outbound.vz.bos2.lab",
      "nics": [
        {
          "ip": "192.168.58.33",
          "mac": "00:00:00:00:00:00",
          "model": "unknown",
          "name": "eth1",
          "pxe": true,
          "speedGbps": 10,
          "vlanId": 0
        }
      ],
      "ramMebibytes": 0,
      "storage": [],
      "systemVendor": {
        "manufacturer": "Red Hat",
        "productName": "product name",
        "serialNumber": ""
      }
    },
    "hardwareProfile": "",
    "lastUpdated": "2023-08-10T21:32:44Z",
    "operationHistory": {
      "deprovision": {
        "end": null,
        "start": null
      },
      "inspect": {
        "end": null,
        "start": null
      },
      "provision": {
        "end": null,
        "start": null
      },
      "register": {
        "end": null,
        "start": null
      }
    },
    "operationalStatus": "discovered",
    "poweredOn": false,
    "provisioning": {
      "ID": "",
      "image": {
        "url": ""
      },
      "state": "unmanaged"
    },
    "triedCredentials": {}
  }
}apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"metal3.io/v1alpha1","kind":"BareMetalHost","metadata":{"annotations":{},"name":"master3.compact.outbound.vz.bos2.lab","namespace":"openshift-machine-api"},"spec":{"automatedCleaningMode":"metadata","bmc":{"address":"","credentialsName":""},"bootMACAddress":"de:ad:be:ff:10:33","bootMode":"legacy","consumerRef":{"apiVersion":"machine.openshift.io/v1beta1","kind":"Machine","name":"compact-7tj89-master3","namespace":"openshift-machine-api"},"customDeploy":{"method":"install_coreos"},"externallyProvisioned":true,"hardwareProfile":"unknown","online":true,"userData":{"name":"master-user-data-managed","namespace":"openshift-machine-api"}}}
  creationTimestamp: "2023-08-10T21:32:43Z"
  finalizers:
  - baremetalhost.metal3.io
  generation: 1
  name: master3.compact.outbound.vz.bos2.lab
  namespace: openshift-machine-api
  resourceVersion: "85974"
  uid: 7059dfed-34d7-4dbb-a293-fb4a99b552f6
spec:
  automatedCleaningMode: metadata
  bmc:
    address: ""
    credentialsName: ""
  bootMACAddress: de:ad:be:ff:10:33
  bootMode: legacy
  consumerRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: Machine
    name: compact-7tj89-master3
    namespace: openshift-machine-api
  customDeploy:
    method: install_coreos
  externallyProvisioned: true
  hardwareProfile: unknown
  online: true
  userData:
    name: master-user-data-managed
    namespace: openshift-machine-api
status:
  errorCount: 0
  errorMessage: ""
  goodCredentials: {}
  hardware:
    cpu:
      arch: x86_64
      clockMegahertz: 2199.998
      count: 4
      flags: []
      model: Intel(R) Xeon(R) CPU E5-2630 v4 @ 2.20GHz
    firmware:
      bios:
        date: 04/01/2014
        vendor: SeaBIOS
        version: 1.11.0-2.el7
    hostname: master3.compact.outbound.vz.bos2.lab
    nics:
    - ip: 192.168.58.33
      mac: "00:00:00:00:00:00"
      model: unknown
      name: eth1
      pxe: true
      speedGbps: 10
      vlanId: 0
    ramMebibytes: 0
    storage: []
    systemVendor:
      manufacturer: Red Hat
      productName: product name
      serialNumber: ""
  hardwareProfile: ""
  lastUpdated: "2023-08-10T21:32:44Z"
  operationHistory:
    deprovision:
      end: null
      start: null
    inspect:
      end: null
      start: null
    provision:
      end: null
      start: null
    register:
      end: null
      start: null
  operationalStatus: discovered
  poweredOn: false
  provisioning:
    ID: ""
    image:
      url: ""
    state: unmanaged
  triedCredentials: {}
Please shutdown the master node which is going to be replaced. continue if it's been down(y/n)?y
yes

OpenShift may take a while to roll out the cluster operators on the new node.
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
|        ID        | STATUS  |                 NAME                 |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
|  c757169c4c512d1 | started | master0.compact.outbound.vz.bos2.lab | https://192.168.58.30:2380 | https://192.168.58.30:2379 |      false |
| 140dd3ff0b8915fb | started | master2.compact.outbound.vz.bos2.lab | https://192.168.58.32:2380 | https://192.168.58.32:2379 |      false |
| ce1358bcdbd663b8 | started | master1.compact.outbound.vz.bos2.lab | https://192.168.58.31:2380 | https://192.168.58.31:2379 |      false |
| d4c1b46a409827fe | started | master3.compact.outbound.vz.bos2.lab | https://192.168.58.33:2380 | https://192.168.58.33:2379 |      false |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
Member  c757169c4c512d1 removed from cluster 264853b0d5cefa58
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
|        ID        | STATUS  |                 NAME                 |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
| 140dd3ff0b8915fb | started | master2.compact.outbound.vz.bos2.lab | https://192.168.58.32:2380 | https://192.168.58.32:2379 |      false |
| ce1358bcdbd663b8 | started | master1.compact.outbound.vz.bos2.lab | https://192.168.58.31:2380 | https://192.168.58.31:2379 |      false |
| d4c1b46a409827fe | started | master3.compact.outbound.vz.bos2.lab | https://192.168.58.33:2380 | https://192.168.58.33:2379 |      false |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+

baremetalhost.metal3.io "master0.compact.outbound.vz.bos2.lab" deleted
machine.machine.openshift.io "compact-7tj89-master-0" deleted

pod "etcd-guard-master0.compact.outbound.vz.bos2.lab" deleted
pod "etcd-guard-master1.compact.outbound.vz.bos2.lab" deleted
pod "etcd-guard-master2.compact.outbound.vz.bos2.lab" deleted
pod "etcd-guard-master3.compact.outbound.vz.bos2.lab" deleted
pod "etcd-master0.compact.outbound.vz.bos2.lab" deleted
pod "etcd-master1.compact.outbound.vz.bos2.lab" deleted
pod "etcd-master2.compact.outbound.vz.bos2.lab" deleted
pod "etcd-master3.compact.outbound.vz.bos2.lab" deleted
pod "installer-10-master0.compact.outbound.vz.bos2.lab" deleted
pod "installer-10-master1.compact.outbound.vz.bos2.lab" deleted
pod "installer-10-master2.compact.outbound.vz.bos2.lab" deleted
pod "installer-11-master3.compact.outbound.vz.bos2.lab" deleted
pod "installer-12-master0.compact.outbound.vz.bos2.lab" deleted
pod "installer-12-master1.compact.outbound.vz.bos2.lab" deleted
pod "installer-12-master2.compact.outbound.vz.bos2.lab" deleted
pod "installer-2-master2.compact.outbound.vz.bos2.lab" deleted
pod "installer-4-master1.compact.outbound.vz.bos2.lab" deleted
pod "installer-6-master1.compact.outbound.vz.bos2.lab" deleted
pod "installer-6-master2.compact.outbound.vz.bos2.lab" deleted
pod "installer-6-retry-1-master2.compact.outbound.vz.bos2.lab" deleted
pod "installer-7-master0.compact.outbound.vz.bos2.lab" deleted
pod "installer-9-master0.compact.outbound.vz.bos2.lab" deleted
pod "installer-9-master1.compact.outbound.vz.bos2.lab" deleted
pod "installer-9-master2.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-10-master0.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-10-master1.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-10-master2.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-10-master3.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-11-master0.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-11-master1.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-11-master2.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-11-master3.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-12-master0.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-12-master1.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-12-master2.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-12-master3.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-6-master0.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-6-master1.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-6-master2.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-7-master0.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-7-master1.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-7-master2.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-8-master0.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-8-master1.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-8-master2.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-9-master0.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-9-master1.compact.outbound.vz.bos2.lab" deleted
pod "revision-pruner-9-master2.compact.outbound.vz.bos2.lab" deleted

You can type ctrl+c to stop the watch below:
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.12.27   True        False         False      7m24s   
baremetal                                  4.12.27   True        False         False      136m    
cloud-controller-manager                   4.12.27   True        False         False      145m    
cloud-credential                           4.12.27   True        False         False      146m    
cluster-autoscaler                         4.12.27   True        False         False      136m    
config-operator                            4.12.27   True        False         False      136m    
console                                    4.12.27   True        False         False      7m21s   
control-plane-machine-set                  4.12.27   True        False         False      136m    
csi-snapshot-controller                    4.12.27   True        False         False      136m    
dns                                        4.12.27   True        False         False      136m    
etcd                                       4.12.27   True        True          False      134m    NodeInstallerProgressing: 1 nodes are at revision 11; 2 nodes are at revision 12; 0 nodes have achieved new revision 15
image-registry                             4.12.27   True        False         False      126m    
ingress                                    4.12.27   True        False         False      129m    
insights                                   4.12.27   True        False         False      118m    
kube-apiserver                             4.12.27   True        True          False      120m    NodeInstallerProgressing: 1 nodes are at revision 8; 1 nodes are at revision 9; 1 nodes are at revision 10
kube-controller-manager                    4.12.27   True        False         True       134m    GarbageCollectorDegraded: error querying alerts: client_error: client error: 403
kube-scheduler                             4.12.27   True        False         False      133m    
kube-storage-version-migrator              4.12.27   True        False         False      136m    
machine-api                                4.12.27   True        False         False      133m    
machine-approver                           4.12.27   True        False         False      136m    
machine-config                             4.12.27   True        False         False      135m    
marketplace                                4.12.27   True        False         False      136m    
monitoring                                 4.12.27   True        False         False      126m    
network                                    4.12.27   True        True          False      136m    DaemonSet "/openshift-ovn-kubernetes/ovnkube-master" update is rolling out (1 out of 3 updated)
node-tuning                                4.12.27   True        False         False      136m    
openshift-apiserver                        4.12.27   True        True          False      7m24s   APIServerDeploymentProgressing: deployment/apiserver.openshift-apiserver: 2/3 pods have been updated to the latest generation
openshift-controller-manager               4.12.27   True        False         False      132m    
openshift-samples                          4.12.27   True        False         False      130m    
operator-lifecycle-manager                 4.12.27   True        False         False      135m    
operator-lifecycle-manager-catalog         4.12.27   True        False         False      136m    
operator-lifecycle-manager-packageserver   4.12.27   True        False         False      130m    
service-ca                                 4.12.27   True        False         False      136m    
storage                                    4.12.27   True        False         False      136m    
network                                    4.12.27   True        True          False      136m    DaemonSet "/openshift-ovn-kubernetes/ovnkube-master" update is rolling out (1 out of 3 updated)
authentication                             4.12.27   True        False         False      7m41s   
authentication                             4.12.27   True        False         False      7m45s   
openshift-apiserver                        4.12.27   True        False         False      7m48s   
authentication                             4.12.27   True        False         False      7m50s   
openshift-apiserver                        4.12.27   True        False         False      7m51s   
network                                    4.12.27   True        True          False      136m    DaemonSet "/openshift-ovn-kubernetes/ovnkube-master" update is rolling out (1 out of 3 updated)
network                                    4.12.27   True        True          False      136m    DaemonSet "/openshift-ovn-kubernetes/ovnkube-master" update is rolling out (1 out of 3 updated)
network                                    4.12.27   True        True          False      136m    DaemonSet "/openshift-ovn-kubernetes/ovnkube-master" update is rolling out (2 out of 3 updated)
kube-apiserver                             4.12.27   True        True          False      121m    NodeInstallerProgressing: 1 nodes are at revision 9; 2 nodes are at revision 10
authentication                             4.12.27   True        False         False      8m8s    
etcd                                       4.12.27   True        True          False      135m    NodeInstallerProgressing: 1 nodes are at revision 11; 2 nodes are at revision 12; 0 nodes have achieved new revision 15
etcd                                       4.12.27   True        True          False      136m    NodeInstallerProgressing: 1 nodes are at revision 11; 2 nodes are at revision 12; 0 nodes have achieved new revision 15
etcd                                       4.12.27   True        True          False      136m    NodeInstallerProgressing: 1 nodes are at revision 11; 2 nodes are at revision 12; 0 nodes have achieved new revision 15
openshift-apiserver                        4.12.27   True        False         False      9m2s    
openshift-apiserver                        4.12.27   True        False         False      9m5s    
openshift-apiserver                        4.12.27   True        False         False      9m10s   

…

authentication                             4.12.27   True        False         False      18m     
baremetal                                  4.12.27   True        False         False      147m    
cloud-controller-manager                   4.12.27   True        False         False      156m    
cloud-credential                           4.12.27   True        False         False      158m    
cluster-autoscaler                         4.12.27   True        False         False      147m    
config-operator                            4.12.27   True        False         False      148m    
console                                    4.12.27   True        False         False      18m     
control-plane-machine-set                  4.12.27   True        False         False      147m    
csi-snapshot-controller                    4.12.27   True        False         False      147m    
dns                                        4.12.27   True        False         False      147m    
etcd                                       4.12.27   True        False         False      145m    
image-registry                             4.12.27   True        False         False      137m    
ingress                                    4.12.27   True        False         False      140m    
insights                                   4.12.27   True        False         False      129m    
kube-apiserver                             4.12.27   True        False         False      131m    
kube-controller-manager                    4.12.27   True        False         False      145m    
kube-scheduler                             4.12.27   True        False         False      144m    
kube-storage-version-migrator              4.12.27   True        False         False      147m    
machine-api                                4.12.27   True        False         False      144m    
machine-approver                           4.12.27   True        False         False      147m    
machine-config                             4.12.27   True        False         False      146m    
marketplace                                4.12.27   True        False         False      147m    
monitoring                                 4.12.27   True        False         False      137m    
network                                    4.12.27   True        False         False      147m    
node-tuning                                4.12.27   True        False         False      147m    
openshift-apiserver                        4.12.27   True        False         False      18m     
openshift-controller-manager               4.12.27   True        False         False      143m    
openshift-samples                          4.12.27   True        False         False      141m    
operator-lifecycle-manager                 4.12.27   True        False         False      146m    
operator-lifecycle-manager-catalog         4.12.27   True        False         False      147m    
operator-lifecycle-manager-packageserver   4.12.27   True        False         False      142m    
service-ca                                 4.12.27   True        False         False      147m    
storage                                    4.12.27   True        False         False      147m    

```
