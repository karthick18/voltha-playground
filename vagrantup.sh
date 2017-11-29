#!/usr/bin/env bash
cd $(dirname $0)
rm -f ansible.log
rm -rf /tmp/ansible/facts_cache
source ./aws_secrets.sh
vagrant destroy -f
vagrant up --provider=aws
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vvv -e ansible_python_interpreter=/usr/bin/python3 provisioning/swarm-playbook.yml
