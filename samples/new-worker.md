```shell
[root@hub-helper ocp-cluster-scale-master]# cd scale/

[root@hub-helper scale]# pwd
/root/ocp-cluster-scale-master/scale

[root@hub-helper scale]# ls -lrt
total 36
-rw-r--r--. 1 root root  560 Aug 25 17:14 config-worker0.yaml
-rw-r--r--. 1 root root  834 Aug 25 17:14 config-sample.yaml
-rw-r--r--. 1 root root  552 Aug 25 17:14 config-master3.yaml
-rwxr-xr-x. 1 root root 4804 Aug 25 17:14 boot-from-iso.sh
-rwxr-xr-x. 1 root root 5268 Aug 25 17:14 add-node.sh
-rwxr-xr-x. 1 root root 3350 Aug 25 17:14 link-machine-and-node.sh
drwxr-xr-x. 2 root root   82 Aug 25 17:23 templates
-rwxr-xr-x. 1 root root 4081 Aug 25 17:23 replace-master.sh

[root@hub-helper scale]# cat config-worker0.yaml 
#MCE hub kubeconfig
hub:
  kubeconfig: kubeconfig-hub.yaml

#The cluster which will be imported
managed:
  kubeconfig: kubeconfig-managed.yaml

#worker node information
node:
  hostname: worker0.compact.outbound.vz.bos2.lab
  role: worker

  bmc:
    address: 192.168.58.15:8080
    username: Administrator
    password: dummy
    kvm_uuid: 22222222-1111-1111-0000-000000000010

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

[root@hub-helper scale]# ./add-node.sh 
Usage: ./add-node.sh config.yaml [nm-state.yaml]
     config.yaml: mandatory, refer to config-sample.yaml
     nm-state.yaml: optional, refer to https://github.com/openshift/assisted-service/blob/master/config/crd/bases/agent-install.openshift.io_nmstateconfigs.yaml
Example 1: ./add-node.sh config-worker1.yaml
Example 2: ./add-node.sh config-master3.yaml nm-state-master3.yaml


[root@hub-helper scale]# ./add-node.sh config-worker0.yaml 
-------------------------------
Cluster information:
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.29   True        False         87m     Cluster version is 4.12.29

Cluster nodes:
NAME                                   STATUS   ROLES                         AGE    VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   102m   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   119m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   119m   v1.25.11+1485cc9

-------------------------------
Customized NMStateConfig CR not provided, new node uses static IP, will create NMStateConfig CR below:
---
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  labels:
    infraenvs.agent-install.openshift.io: compact
  name: worker0.compact.outbound.vz.bos2.lab
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
-------------------------------
Power off server.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000010/Actions/ComputerSystem.Reset
-------------------------------

204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia
-------------------------------

Insert Virtual Media: https://assisted-image-service-multicluster-engine.apps.mce.outbound.vz.bos2.lab/images/58d6de51-c013-49b9-9c28-2cc0844ffcae?api_key=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbmZyYV9lbnZfaWQiOiI1OGQ2ZGU1MS1jMDEzLTQ5YjktOWMyOC0yY2MwODQ0ZmZjYWUifQ.LRYaXh_h49hBOL6alEXysGyQdglDjpXJFR04nlRMxxiHtQ0E7y2kjCdCSxJ8WUge8ffSrTmGkSH5hU3Tc-ddyw&arch=x86_64&type=minimal-iso&version=4.12
204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000010/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia
-------------------------------

Boot node from Virtual Media Once
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000010
-------------------------------

Power on server.
Eject the Virtual Media.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000010/Actions/ComputerSystem.Reset

-------------------------------
Node booting.

-------------------------------
22222222-1111-1111-0000-000000000010             false      auto-assign   
Patching the agent to approve the node and trigger the deployment.
patch /spec/hostname with: worker0.compact.outbound.vz.bos2.lab
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
patch /spec/approved with: true
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
patch /spec/role with: worker
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
patch /spec/clusterDeploymentName with {"name": "compact", "namespace": "compact"}
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000010 patched
-------------------------------
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed 33/100
Installation in progress: completed 33/100
Installation in progress: completed 55/100
Installation in progress: completed 55/100
Installation in progress: completed 55/100
Installation in progress: completed 55/100
Installation in progress: completed 55/100
Installation in progress: completed 55/100
Installation in progress: completed 55/100
Installation in progress: completed 55/100
Installation completed.

-------------------------------
Cluster information:
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.29   True        False         100m    Cluster version is 4.12.29

Cluster nodes:
NAME                                   STATUS   ROLES                         AGE    VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   115m   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   132m   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   132m   v1.25.11+1485cc9
worker0.compact.outbound.vz.bos2.lab   Ready    worker                        72s    v1.25.11+1485cc9

```