#!/bin/bash

# kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
export ARGO_ADMIN_PASSWORD=