```shell
[root@hub-helper scale]# cat config-master3.yaml 
#MCE hub kubeconfig
hub:
  kubeconfig: /root/workload-enablement/kubeconfigs/kubeconfig-mce.yaml

#The cluster which will be imported
managed:
  kubeconfig: /root/workload-enablement/kubeconfigs/kubeconfig-compact.yaml

node:
  hostname: master3.compact.outbound.vz.bos2.lab
  role: master
  
  bmc:
    address: 192.168.58.15:8080
    username: Administrator
    password: dummy
    kvm_uuid: 22222222-1111-1111-0000-000000000003

  network:
    dhcp: false
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

[root@hub-helper scale]# cat config-master3.yaml 
#MCE hub kubeconfig
hub:
  kubeconfig: /root/workload-enablement/kubeconfigs/kubeconfig-mce.yaml

#The cluster which will be imported
managed:
  kubeconfig: /root/workload-enablement/kubeconfigs/kubeconfig-compact.yaml

node:
  hostname: master3.compact.outbound.vz.bos2.lab
  role: master
  
  bmc:
    address: 192.168.58.15:8080
    username: Administrator
    password: dummy
    kvm_uuid: 22222222-1111-1111-0000-000000000003

  network:
    dhcp: false
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

[root@hub-helper scale]# ./add-node.sh config-master3.yaml 
-------------------------------
Cluster information:
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.29   True        False         43h     Cluster version is 4.12.29

Cluster nodes:
NAME                                   STATUS   ROLES                         AGE   VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   43h   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   43h   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   43h   v1.25.11+1485cc9
worker0.compact.outbound.vz.bos2.lab   Ready    worker                        41h   v1.25.11+1485cc9

-------------------------------
Customized NMStateConfig CR not provided, new node uses static IP, will create NMStateConfig CR below:
---
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  labels:
    infraenvs.agent-install.openshift.io: compact
  name: master3.compact.outbound.vz.bos2.lab
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
-------------------------------
Power off server.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000003/Actions/ComputerSystem.Reset
-------------------------------

204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia
-------------------------------

Insert Virtual Media: https://assisted-image-service-multicluster-engine.apps.mce.outbound.vz.bos2.lab/images/58d6de51-c013-49b9-9c28-2cc0844ffcae?api_key=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbmZyYV9lbnZfaWQiOiI1OGQ2ZGU1MS1jMDEzLTQ5YjktOWMyOC0yY2MwODQ0ZmZjYWUifQ.LuiUoRC78IgoOowMZfzzlgeePXVuHpaSxAkI9FrzgL3pTliB25SLbR5CWLFJ5xp2lkbNj0wQ9WmxOHsig-bnwQ&arch=x86_64&type=minimal-iso&version=4.12
204 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia
-------------------------------

Boot node from Virtual Media Once
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000003
-------------------------------

Power on server.
Eject the Virtual Media.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000003/Actions/ComputerSystem.Reset

-------------------------------
Node booting.

-------------------------------
22222222-1111-1111-0000-000000000003             false      auto-assign   
Patching the agent to approve the node and trigger the deployment.
patch /spec/hostname with: master3.compact.outbound.vz.bos2.lab
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
patch /spec/approved with: true
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
patch /spec/role with: master
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
patch /spec/clusterDeploymentName with {"name": "compact", "namespace": "compact"}
agent.agent-install.openshift.io/22222222-1111-1111-0000-000000000003 patched
-------------------------------
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed /100
Installation in progress: completed 42/100
Installation in progress: completed 42/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation in progress: completed 57/100
Installation completed.

-------------------------------
Cluster information:
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.29   True        False         43h     Cluster version is 4.12.29

Cluster nodes:
NAME                                   STATUS   ROLES                         AGE   VERSION
master0.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   43h   v1.25.11+1485cc9
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   44h   v1.25.11+1485cc9
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   44h   v1.25.11+1485cc9
master3.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   78s   v1.25.11+1485cc9
worker0.compact.outbound.vz.bos2.lab   Ready    worker                        41h   v1.25.11+1485cc9

```