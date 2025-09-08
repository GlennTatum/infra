#!/bin/bash

if [[ $1 = 'destroy' ]]; then
    for ((NODE=1; NODE <= 5; NODE++)); do
        echo "Shutting down ubuntu-node-$NODE"
        virsh shutdown ubuntu-node-$NODE 2> /dev/null
    done
    sleep 5
    for ((NODE=1; NODE <= 5; NODE++)); do
        echo "Removing down ubuntu-node-$NODE"
        virsh undefine ubuntu-node-$NODE --remove-all-storage 2> /dev/null
    done
    exit 0
fi

virsh list --all | grep ubuntu-node 2> /dev/null

if [ $? = 1 ]; then
        if [[ -z $(ls *\-[1-9].img 2> /dev/null) ]]; then
            echo "Please run ./prerun.sh before configuring virtual machines"
            exit -1
        fi
        echo "Creating virtual machines..."
        for ((NODE=1; NODE <= 5; NODE++)); do
            virt-install --name=ubuntu-node-$NODE \
            --ram=2048 \
            --vcpus=1 \
            --import \
            --disk path=noble-server-cloudimg-amd64-$NODE.img,format=qcow2 \
            --os-variant=ubuntu22.04 \
            --network bridge=virbr0,model=virtio \
            --cloud-init user-data=imds/user-data.yaml,network-config=imds/network-config-$NODE.yaml \
            --noautoconsole
        done
    else
    echo "Starting nodes..."
    for ((NODE=1; NODE <= 5; NODE++)); do
        virsh start ubuntu-node-$NODE 2> /dev/null
        if [ $? != 0 ]; then
            echo "Nodes are already running!"
            exit 0
        fi
    done
fi



