```bash
ansible-playbook -i inventory.ini --private-key ~/.ssh/private-key --user $REMOTE_USER -K playbook.yml
```