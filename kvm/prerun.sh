#!/bin/bash

for ((IMG=1; IMG <= 5; IMG++)); do
    cp noble-server-cloudimg-amd64.img noble-server-cloudimg-amd64-$IMG.img
    qemu-img resize noble-server-cloudimg-amd64-$IMG.img 15G
done