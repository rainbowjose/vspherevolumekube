**Basic requirements**

Update your ESXI to latest(6.7 U3) version from "ESXi shell":
```esxcli software profile update -p ESXi-6.7.0-20200403001-standard -d https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml```
or, in other case, from your vCenter

Upadate your vCenter also.

**1. ProviderID env on ALL nodes.**

It can be applied by script:
```
#!/bin/bash

PAIRS=$(kubectl get nodes -o json | jq -r -c '.items[]|[.metadata.name, .status.nodeInfo.systemUUID]' | tr -d '[]"')
for vm in $PAIRS; do
	VM_NAME=${vm%,*}
	VM_UUID=${vm#*,}
	echo Patching $VM_NAME with $VM_UUID
	kubectl patch node $VM_NAME -p "{\"spec\":{\"providerID\":\"vsphere://$VM_UUID\"}}"
done
```

OR you can use updateproviderid package in that way:
```helm install updateproviderid .```

and then
```helm delete updateproviderid```

it may be useful if you do not want to run any scripts for some reasons.

Check presence of the necessary parameters:
```kubectl get nodes -o json | jq '.items[]|[.metadata.name, .spec.providerID, .status.nodeInfo.systemUUID]'```

**2. vSphere CPI and vSphere CSI things installed in your kubernetes cluster**

CPI - Cloud Provider Interface, a thing for aplying UUIDs and some unobivious managing shit.

https://github.com/kubernetes/cloud-provider-vsphere

CSI - Container Storage Interface, driver that must be installed on all your nodes, required to connect your cluster to vSphere.

https://github.com/kubernetes-sigs/vsphere-csi-driver/tree/master/manifests

You can find required configuration guides inside repo's

**3. Create your SC and PVC for smoke-testing**
```
apiVersion: v1
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fast
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: csi.vsphere.vmware.com
```
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: fast
```


**Troubleshooting**

If you re cant edit ProviderID and get message like this: 

* spec.providerID: Forbidden: node updates may not change providerID except from "" to valid
* []: Forbidden: node updates may only change labels, taints, or capacity (or configSource, if the DynamicKubeletConfig feature gate is enabled)

You can do this: 
```kubectl delete node node1```

*reboot node*

Now the master nodes are gone, lets restore them:
```kubectl label nodes node1 node-role.kubernetes.io/master=```

And then apply patch again!
