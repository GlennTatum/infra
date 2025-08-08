# infra
Developer friendly Kubernetes Infrastructure

### TODO
- Configure k0s.yaml
- Configure HAProxy to route 80 -> 30080 and 443 -> 300443


### Pre-Requisites
Helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```