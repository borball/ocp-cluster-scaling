## Add a master

```shell
# ./add-node.sh config-master3.yaml
-------------------------------
Cluster information:
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.41   True        False         29m     Error while reconciling 4.12.41: an unknown error has occurred: MultipleErrors

Cluster nodes:
NAME                                   STATUS     ROLES                         AGE   VERSION
master0.compact.outbound.vz.bos2.lab   NotReady   control-plane,master,worker   38m   v1.25.14+31e0558
master1.compact.outbound.vz.bos2.lab   Ready      control-plane,master,worker   57m   v1.25.14+31e0558
master2.compact.outbound.vz.bos2.lab   Ready      control-plane,master,worker   57m   v1.25.14+31e0558

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
Installation started: 11/15/23 02:09:35
-------------------------------
-------------------------------
Power off server.
204 https://192.168.58.15:8080/redfish/v1/Systems/22222222-1111-1111-0000-000000000003/Actions/ComputerSystem.Reset
-------------------------------

{
"error": {
"code": "Base.1.0.GeneralError",
"message": "[Errno 2] No such file or directory: \u0027/tmp/tmpjdx0y72u/3adf9c00-341f-460b-ad93-648bda0b8b5a\u0027",
"@Message.ExtendedInfo": [
{
"@odata.type": "/redfish/v1/$metadata#Message.1.0.0.Message",
"MessageId": "Base.1.0.GeneralError"
}
]
}
}500 https://192.168.58.15:8080/redfish/v1/Managers/22222222-1111-1111-0000-000000000003/VirtualMedia/Cd/Actions/VirtualMedia.EjectMedia
-------------------------------

Insert Virtual Media: https://assisted-image-service-multicluster-engine.apps.compact.outbound.vz.bos2.lab/images/bd783c48-e038-4c74-8686-f315f3279dec?api_key=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbmZyYV9lbnZfaWQiOiJiZDc4M2M0OC1lMDM4LTRjNzQtODY4Ni1mMzE1ZjMyNzlkZWMifQ.bvs7jmmBLTV8oEq_KbCZ8A0K9fF6M_YnCjD2ZqyOic3os2MV1wi1noESmQIMjBKQyeadrtvPj-7Tuzb4QlE-Mw&arch=x86_64&type=minimal-iso&version=4.12
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
Node agent registered.
NAME                                   CLUSTER   APPROVED   ROLE          STAGE
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
Installation in progress: completed 85/100
Installation completed: 11/15/23 02:22:27
-------------------------------
Cluster information:
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.41   True        False         42m     Error while reconciling 4.12.41: an unknown error has occurred: MultipleErrors

Cluster nodes:
NAME                                   STATUS     ROLES                         AGE    VERSION
master0.compact.outbound.vz.bos2.lab   NotReady   control-plane,master,worker   51m    v1.25.14+31e0558
master1.compact.outbound.vz.bos2.lab   Ready      control-plane,master,worker   70m    v1.25.14+31e0558
master2.compact.outbound.vz.bos2.lab   Ready      control-plane,master,worker   71m    v1.25.14+31e0558
master3.compact.outbound.vz.bos2.lab   Ready      control-plane,master,worker   110s   v1.25.14+31e0558
```

## Replace broken master

```shell
# ./replace-master.sh master0.compact.outbound.vz.bos2.lab master3.compact.outbound.vz.bos2.lab
-------------------------------
Node master0.compact.outbound.vz.bos2.lab exist will be replaced.
Node master3.compact.outbound.vz.bos2.lab will be the new master.
-------------------------------
Create BaremetalHost and Machine for the new master.
baremetalhost.metal3.io/master3.compact.outbound.vz.bos2.lab created
machine.machine.openshift.io/compact-mn6f8-master3 created
-------------------------------
Link the new created BaremetalHost and Machine.
Waiting for oc_proxy to respond.Starting to serve on 127.0.0.1:8001
 Success!
{
  "apiVersion": "metal3.io/v1alpha1",
  "kind": "BareMetalHost",
  "metadata": {
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"metal3.io/v1alpha1\",\"kind\":\"BareMetalHost\",\"metadata\":{\"annotations\":{},\"name\":\"master3.compact.outbound.vz.bos2.lab\",\"namespace\":\"openshift-machine-api\"},\"spec\":{\"automatedCleaningMode\":\"metadata\",\"bmc\":{\"address\":\"\",\"credentialsName\":\"\"},\"bootMACAddress\":\"00:00:00:00:00:02\",\"bootMode\":\"legacy\",\"consumerRef\":{\"apiVersion\":\"machine.openshift.io/v1beta1\",\"kind\":\"Machine\",\"name\":\"compact-mn6f8-master3\",\"namespace\":\"openshift-machine-api\"},\"customDeploy\":{\"method\":\"install_coreos\"},\"externallyProvisioned\":true,\"hardwareProfile\":\"unknown\",\"online\":true,\"userData\":{\"name\":\"master-user-data-managed\",\"namespace\":\"openshift-machine-api\"}}}\n"
    },
    "creationTimestamp": "2023-11-15T02:59:04Z",
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
            "f:finalizers": {
              ".": {},
              "v:\"baremetalhost.metal3.io\"": {}
            }
          }
        },
        "manager": "baremetal-operator",
        "operation": "Update",
        "time": "2023-11-15T02:59:04Z"
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
        "time": "2023-11-15T02:59:04Z"
      },
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
        "time": "2023-11-15T02:59:04Z"
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
        "time": "2023-11-15T02:59:40Z"
      }
    ],
    "name": "master3.compact.outbound.vz.bos2.lab",
    "namespace": "openshift-machine-api",
    "resourceVersion": "82728",
    "uid": "9a4da6a8-74a1-4fa3-b5a0-0e8667054613"
  },
  "spec": {
    "automatedCleaningMode": "metadata",
    "bmc": {
      "address": "",
      "credentialsName": ""
    },
    "bootMACAddress": "00:00:00:00:00:02",
    "bootMode": "legacy",
    "consumerRef": {
      "apiVersion": "machine.openshift.io/v1beta1",
      "kind": "Machine",
      "name": "compact-mn6f8-master3",
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
    "lastUpdated": "2023-11-15T02:59:04Z",
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
}-------------------------------
-------------------------------
ETCD member list:
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
|        ID        | STATUS  |                 NAME                 |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
| 89721a35fbd328fb | started | master2.compact.outbound.vz.bos2.lab | https://192.168.58.32:2380 | https://192.168.58.32:2379 |      false |
| caf85f91f2ed32be | started | master0.compact.outbound.vz.bos2.lab | https://192.168.58.30:2380 | https://192.168.58.30:2379 |      false |
| d00f4f032364d115 | started | master1.compact.outbound.vz.bos2.lab | https://192.168.58.31:2380 | https://192.168.58.31:2379 |      false |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
-------------------------------
Delete old BaremetalHost and Machine.
baremetalhost.metal3.io "master0.compact.outbound.vz.bos2.lab" deleted
machine.machine.openshift.io "compact-mn6f8-master-0" deleted
-------------------------------
-------------------------------
ETCD member list:
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
|        ID        | STATUS  |                 NAME                 |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
| 89721a35fbd328fb | started | master2.compact.outbound.vz.bos2.lab | https://192.168.58.32:2380 | https://192.168.58.32:2379 |      false |
| caf85f91f2ed32be | started | master0.compact.outbound.vz.bos2.lab | https://192.168.58.30:2380 | https://192.168.58.30:2379 |      false |
| d00f4f032364d115 | started | master1.compact.outbound.vz.bos2.lab | https://192.168.58.31:2380 | https://192.168.58.31:2379 |      false |
+------------------+---------+--------------------------------------+----------------------------+----------------------------+------------+
NAME                                   STATUS   ROLES                         AGE    VERSION
master1.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   108m   v1.25.14+31e0558
master2.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   109m   v1.25.14+31e0558
master3.compact.outbound.vz.bos2.lab   Ready    control-plane,master,worker   39m    v1.25.14+31e0558
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.12.41   True        True          False      71m     OAuthServerDeploymentProgressing: deployment/oauth-openshift.openshift-authentication: observed generation is 7, desired generation is 8.
baremetal                                  4.12.41   True        False         False      101m    
cloud-controller-manager                   4.12.41   True        False         False      108m    
cloud-credential                           4.12.41   True        False         False      112m    
cluster-autoscaler                         4.12.41   True        False         False      101m    
config-operator                            4.12.41   True        False         False      102m    
console                                    4.12.41   True        False         False      71m     
control-plane-machine-set                  4.12.41   True        False         False      101m    
csi-snapshot-controller                    4.12.41   True        False         False      101m    
dns                                        4.12.41   True        False         False      101m    
etcd                                       4.12.41   True        True          True       100m    ClusterMemberControllerDegraded: unhealthy members found during reconciling members...
image-registry                             4.12.41   True        False         False      92m     
ingress                                    4.12.41   True        False         False      94m     
insights                                   4.12.41   True        False         False      89m     
kube-apiserver                             4.12.41   True        False         False      98m     
kube-controller-manager                    4.12.41   True        False         False      99m     
kube-scheduler                             4.12.41   True        False         False      98m     
kube-storage-version-migrator              4.12.41   True        False         False      102m    
machine-api                                4.12.41   True        False         False      98m     
machine-approver                           4.12.41   True        False         False      101m    
machine-config                             4.12.41   True        False         False      13s     
marketplace                                4.12.41   True        False         False      101m    
monitoring                                 4.12.41   True        False         False      70m     
network                                    4.12.41   True        True          False      101m    DaemonSet "/openshift-ovn-kubernetes/ovnkube-master" update is rolling out (1 out of 3 updated)...
node-tuning                                4.12.41   True        False         False      101m    
openshift-apiserver                        4.12.41   True        False         False      71m     
openshift-controller-manager               4.12.41   True        False         False      97m     
openshift-samples                          4.12.41   True        False         False      94m     
operator-lifecycle-manager                 4.12.41   True        False         False      101m    
operator-lifecycle-manager-catalog         4.12.41   True        False         False      101m    
operator-lifecycle-manager-packageserver   4.12.41   True        False         False      72m     
service-ca                                 4.12.41   True        False         False      102m    
storage                                    4.12.41   True        False         False      102m    
The master node has been replaced, but it may take time to roll out all cluster operators to the new node.
Please run oc get co -w to monitor if all cluster operators are available and not downgraded.
```