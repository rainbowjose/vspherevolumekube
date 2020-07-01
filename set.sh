#!/bin/bash

PAIRS=$(kubectl get nodes -o json | jq -r -c '.items[]|[.metadata.name, .status.nodeInfo.systemUUID]' | tr -d '[]"')
for vm in $PAIRS; do
	VM_NAME=${vm%,*}
	VM_UUID=${vm#*,}
	echo Patching $VM_NAME with $VM_UUID
	kubectl patch node $VM_NAME -p "{\"spec\":{\"providerID\":\"vsphere://${v:6:2}${v:4:2}${v:2:2}${v:0:2}-${v:11:2}${v:9:2}-${v:16:2}${v:14:2}${v:18:36}\"}}"
done
