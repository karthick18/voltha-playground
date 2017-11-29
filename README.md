# VOLTHA Playground on AWS
The purpose of this project is to demonstrate a quick start deployment of
VOLTHA using VMs to build a 3 node highly available Docker Swarm cluster on
which VOLTHA can be stated without the need to build the source code tree or
use, a rather large, off-line mode installer.

You need your own aws_secrets.sh credentials and keyfile before running the steps below.
Modify aws_secrets.sh with the right credentials.

## 2 Easy Steps
1. `git clone and checkout aws' from this repository
```
git clone http://github.com/ciena/voltha-playground
git checkout aws
```
2. sh vagrantup.sh
```

## Verification

### Services Running
In case of any ansible error during voltha deploy, just re-run the swarm-playbook.yml after sourcing aws_secrets.sh.
Refer to the last line of vagrantup.sh for running the playbook
```
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vvv -e ansible_python_interpreter=/usr/bin/python3 provisioning/swarm-playbook.yml
```


In order to access vagrant AWS instances [seed0, manager0, manager1]:
```
source ./aws_secrets.sh
vagrant ssh seed0
vagrant ssh manager0
vagrant ssh manager1
```

**NOTE:** This will go away once the Docker edge release becomes stable and
works.
