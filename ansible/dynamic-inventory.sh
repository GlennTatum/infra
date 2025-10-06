#!/bin/bash
az vmss nic list --resource-group node-infra-group-eastus2 --vmss-name global-kubernetes-vm-scale-set | jq '.[] | .["ipConfigurations"] | .[0] | .["privateIPAddress"]' 
