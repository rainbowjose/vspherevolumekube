#!/bin/bash

PAIRS=$(kubectl get nodes -o json | jq -r -c '.items[]|[.metadata.name, .status.nodeInfo.systemUUID]' | tr -d '[]"')
for vm in $PAIRS; do
	VM_NAME=${vm%,*}
	VM_UUID=${vm#*,}
	echo Patching $VM_NAME with $VM_UUID
	kubectl patch node $VM_NAME -p "{\"spec\":{\"providerID\":\"vsphere://$VM_UUID\"}}"
done
