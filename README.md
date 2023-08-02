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
       If the hub-cluster-kubeconfig equals to spoke-cluster-kubeconfig, it means it is going to expand tge cluster itself.
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

### Add worker node 

- Download the discovery ISO:

    ```shell
    $ cd scale
    ./download-iso.sh <cluster-name>
    ```

    The ISO file will be saved as discovery.iso in the current folder, you can transfer it to your web server so that the BMC console of the new worker node can mount the ISO as virtual media. You don't need to mount the ISO manually, the script below will do. 

    Then you can follow the steps below to boot the new worker node and add it into the cluster.


- Prepare a config file like config-worker.yaml, following is an example:

  ```yaml
  #kueconfig location of MCE hub instance
  hub:
    kubeconfig: ./kubeconfig-compact.yaml

  #name of the cluster which is going to expand
  cluster:
    name: compact
  
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
    #bmc info of worker node
    bmc:
      address: 192.168.58.15:8080
      username: Administrator
      password: dummy
      #optional, specify it if sushy-tools is being used as BMC emulator
      kvm_uuid: 22222222-1111-1111-0000-000000000003

  ```


- Add the worker into the cluster

  ```shell
  $ cd worker
  $ ./add.sh config-compact.yaml   
  ```
  
  The script will boot the new worker node from the discovery ISO and start the OpenShift deployment, Following is an execution sample:
 
  ```shell
  $ ./add.sh config-worker1.yaml 
  Worker node uses static IP, will create nmstateconfig
  ---
  apiVersion: agent-install.openshift.io/v1beta1
  kind: NMStateConfig
  metadata:
  labels:
  infraenvs.agent-install.openshift.io: compact
  name: worker1.compact.outbound.vz.bos2.lab
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
  
  
  nmstateconfig.agent-install.openshift.io/worker1.compact.outbound.vz.bos2.lab unchanged
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
  
  No resources found in compact namespace.
  No resources found in compact namespace.
  No resources found in compact namespace.
  22222222-1111-1111-0000-000000000003             false      auto-assign   
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
  -------------------------------
  Installation in progress: completed /100
  Installation in progress: completed /100
  Installation in progress: completed 11/100
  Installation in progress: completed 33/100
  Installation in progress: completed 55/100
  Installation in progress: completed 55/100
  Installation completed.
  NAME                                   STATUS   ROLES                         AGE    VERSION
  master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   96m    v1.25.11+1485cc9
  master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   115m   v1.25.11+1485cc9
  master3.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   116m   v1.25.11+1485cc9
  worker1.compact.outbound.vz.bos2.lab   Ready    worker                        65s    v1.25.11+1485cc9
  ```

###  Replace a master node

- Download the discovery ISO:

    ```shell
    $ cd scale
    ./download-iso.sh <cluster-name>
    ```

  The ISO file will be saved as discovery.iso in the current folder, you can transfer it to your web server so that the BMC console of the new master node can mount the ISO as virtual media. You don't need to mount the ISO manually, the script below will do.

  Then you can follow the steps below to boot the new master node and add it into the cluster.


- Prepare a config file like config-master.yaml, following is an example:

  ```yaml
  #kueconfig location of MCE hub instance
  hub:
    kubeconfig: /root/workload-enablement/sno/kubeconfig-compact.yaml
  
  #name of the cluster which is going to expand
  cluster:
    name: compact
  
  #where the discovery iso located, this will be mounted on the BMC of the additional worker node to do the installation
  iso:
    address: http://192.168.58.15/iso/compact-discovery.iso
  
  #master node information
  master:
    replaced: master3.compact.outbound.vz.bos2.lab
    #it won't create nmstateconfig if dhcp is true
    dhcp: false
    hostname: master0.compact.outbound.vz.bos2.lab
    dns:
      - 192.168.58.15
      #- 2600:52:7:58::15
    interface: ens1f0
    mac: de:ad:be:ff:10:34
    ipv4:
      enabled: true
      ip: 192.168.58.34
      prefix: 25
      gateway: 192.168.58.1
    ipv6:
      enabled: false
      ip: 2600:52:7:58::58
      prefix: 64
      gateway: 2600:52:7:58::1
    bmc:
      address: 192.168.58.15:8080
      username: Administrator
      password: dummy
      kvm_uuid: 22222222-1111-1111-0000-000000000004
  
  ```
  
- Add a master into the cluster

  ```shell
  $ cd master
  $ ./add.sh <config-file>
  ```

  The script will boot the new master node from the discovery ISO and start the OpenShift deployment, Following is an execution sample:

  ```shell
  $ ./add.sh config-master0.yaml
  Master node uses static IP, will create nmstateconfig
  ---
  apiVersion: agent-install.openshift.io/v1beta1
  kind: NMStateConfig
  metadata:
  labels:
  infraenvs.agent-install.openshift.io: compact
  name: master0.compact.outbound.vz.bos2.lab
  namespace: compact
  spec:
  interfaces:
  - macAddress: de:ad:be:ff:10:34
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
        mac-address: de:ad:be:ff:10:34
        ipv4:
          address:
          - ip: 192.168.58.34
            prefix-length: 25
          enabled: true
          dhcp: false
        
      routes:
        config:
        - destination: 0.0.0.0/0
          next-hop-address: 192.168.58.1
          next-hop-interface: ens1f0
  
  
  nmstateconfig.agent-install.openshift.io/master0.compact.outbound.vz.bos2.lab created
  -------------------------------
  Power off server.
  204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000004/Actions/ComputerSystem.Reset
  -------------------------------
  
  204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000004/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia
  -------------------------------
  
  Insert Virtual Media: http://192.168.58.15/iso/compact-discovery.iso
  204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000004/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia
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
  "target": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000004/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia"
  },
  "#VirtualMedia.InsertMedia": {
  "target": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000004/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia"
  },
  "Oem": {}
  },
  "UserName": "",
  "Password": "",
  "Certificates": {
  "@odata.id": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000004/VirtualMedia/Cd/Certificates"
  },
  "VerifyCertificate": false,
  "@odata.context": "/redfish/v1/$metadata#VirtualMedia.VirtualMedia",
  "@odata.id": "/redfish/v1/Managers/22222222-1111-1111-0000-000000000004/VirtualMedia/Cd",
  "@Redfish.Copyright": "Copyright 2014-2017 Distributed Management Task Force, Inc. (DMTF). For the full DMTF copyright policy, see http://www.dmtf.org/about/policies/copyright."
  }
  -------------------------------
  
  Boot node from Virtual Media Once
  204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000004
  -------------------------------
  
  Power on server.
  204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000004/Actions/ComputerSystem.Reset
  
  -------------------------------
  Node is booting from virtual media mounted with http://192.168.58.15/iso/compact-discovery.iso, check your BMC console to monitor the progress.
  
  
  Node booting.
  
  22222222-1111-1111-0000-000000000004             false      auto-assign   
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000004 patched
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000004 patched
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000004 patched
  agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000004 patched
  -------------------------------
  Installation in progress: completed /100
  Installation in progress: completed /100
  Installation in progress: completed 42/100
  Installation in progress: completed 57/100
  Installation in progress: completed 57/100
  Installation completed.
  NAME                                   STATUS   ROLES                         AGE     VERSION
  master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   65s     v1.25.11+1485cc9
  master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   6h46m   v1.25.11+1485cc9
  master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   7h6m    v1.25.11+1485cc9
  master3.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   7h6m    v1.25.11+1485cc9
  worker1.compact.outbound.vz.bos2.lab   Ready    worker                        5h11m   v1.25.11+1485cc9
  
  ```
