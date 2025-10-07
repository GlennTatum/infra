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
1. Configure the kuberentes nodes
```bash
ansible-playbook -i inventory.ini --private-key ~/.ssh/private-key --user ubuntu -K playbooks/cluster.yml
# Setup haproxy
ansible-playbook -i inventory.ini --private-key ~/.ssh/private-key --user ubuntu -K playbooks/haproxy.yml
# Reboot the hosts
```
2. Install kubernetes
```bash
# 1. Run k0sctl
env SSH_KNOWN_HOSTS=/dev/null k0sctl apply -c k0sctl.yaml
# On any controller machine grab the admin kubeconfig
k0s kubeconfig admin
```
3. Setup nginx
```bash
cd bootstrap/nginx-ingress
helm install nginx-release . 
```
