# infra
Developer friendly Kubernetes Infrastructure

### Pre-Requisites
1. Install ansible 
    - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
1. Install k0sctl 
    - https://github.com/k0sproject/k0sctl
1. Install kubectl 
    - https://kubernetes.io/docs/tasks/tools/
1. Install helm 
    - https://helm.sh/docs/intro/install/

### Installation
1. Configure the nodes
```bash
ansible-playbook -i inventory.ini --private-key ~/.ssh/private-key --user $REMOTE_USER -K playbooks/cluster.yml
```
2. Install kubernetes
```bash
# 1. Run k0sctl
env SSH_KNOWN_HOSTS=/dev/null k0sctl apply -c k0sctl.yaml # prevent from known_hosts conflicting
# 2. Install the nginx-ingress controller
cd bootstrap/nginx-ingress
helm install nginx-release . 
```

### Recommendations
DNS Host Name Resolution (Local Development)
- Use /etc/hosts for static hostname resolution
- Use a service like CoreDNS to configure resolution