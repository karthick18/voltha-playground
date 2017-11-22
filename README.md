# VOLTHA Playground
The purpose of this project is to demonstrate a quick start deployment of
VOLTHA using VMs to build a 3 node highly available Docker Swarm cluster on
which VOLTHA can be stated without the need to build the source code tree or
use, a rather large, off-line mode installer.

## Five Easy Steps (Four of which are to deploy Docker Swarm)
1. `git clone` this repository
```
git clone http://github.com/ciena/voltha-playground
```
2. `vagrant up` the VMs
```
cd voltha-playround
vagrant up
```
3. `get.docker.io` to bootstrap node
```
vagrant ssh voltha1
curl -sSL get.docker.io | sudo CHANNEL=stable bash
```
4. `ansible-playbook` to install the Docker Swarm cluster
```
sudo docker run -v /vagrant:/data -ti opencord/voltha-ansible \
    -i /data/inventory.ini /data/swarm-playbook.yml
```
5. `docker stack deploy` voltha
```
sudo docker stack deploy -c /vagrant/voltha-stack-3-masters.yml voltha
```

## Verification

### Services Running
It may take a while for all the services to start up and containers will be
downloaded from `dockerhub.com` and started. Eventually you should be able to
use the `sudo docker service ls` command to see an output similar to the
following:
```
ID                  NAME                          MODE                REPLICAS            IMAGE                              PORTS
mgpm879gg4pd        voltha_cli                    replicated          3/3                 opencord/voltha-cli:latest         *:5022->22/tcp
8o4c0xti01wf        voltha_consul                 global              3/3                 consul:0.9.2                       *:8300->8300/tcp,*:8400->8400/tcp,*:8500->8500/tcp,*:8600->8600/udp
9llu0y5l6dmi        voltha_fluentd                replicated          3/3                 opencord/voltha-fluentd:latest     *:30001->24224/tcp
24d2w2itc6ph        voltha_fluentdactv            replicated          1/1                 opencord/voltha-fluentd:latest     *:30002->24224/tcp
p4q2g94mjv6r        voltha_fluentdstby            replicated          1/1                 opencord/voltha-fluentd:latest     *:30000->24224/tcp
95bvynpuzao1        voltha_freeradius             replicated          0/0                 marcelmaatkamp/freeradius:latest   *:1812->1812/udp,*:1813->1813/tcp,*:18120->18120/tcp
twviy341p7oz        voltha_kafka                  global              3/3                 wurstmeister/kafka:1.0.0           *:9092->9092/tcp
hstccmxkgxkz        voltha_netconf                global              3/3                 opencord/voltha-netconf:latest     *:830->1830/tcp
dthmbfhmetal        voltha_ofagent                replicated          1/1                 opencord/voltha-ofagent:latest
ihw5v3e399yg        voltha_onos                   replicated          1/1                 opencord/voltha-onos:latest        *:6653->6653/tcp,*:8101->8101/tcp,*:8181->8181/tcp
z01e74n2ik3t        voltha_onos_cluster_manager   replicated          1/1                 opencord/voltha-unum:latest        *:5411->5411/tcp
ws317b7cklkf        voltha_tools                  replicated          1/1                 opencord/voltha-tools:latest       *:4022->22/tcp
hofvkdwqchgm        voltha_vcore                  replicated          3/3                 opencord/voltha:latest             *:8880->8880/tcp,*:18880->18880/tcp,*:50556->50556/tcp
gh2emeprfkcd        voltha_voltha                 replicated          1/1                 opencord/voltha-envoy:latest       *:8001->8001/tcp,*:8443->8443/tcp,*:8882->8882/tcp,*:50555->50555/tcp
png5mujaf8q3        voltha_zk1                    replicated          1/1                 zookeeper:3.4.11
6a3ps0pflm4g        voltha_zk2                    replicated          1/1                 zookeeper:3.4.11
znecxzc1fyhq        voltha_zk3                    replicated          1/1                 zookeeper:3.4.11
```

The system could take a few to several minutes to get to this state based on
network connection bandwidth as well as compute power. The key attribute
to notice is the `REPLICAS` column, where all the expected instances are
running, i.e. the numbers match.

**NOTE:** No instances of FreeRADIUS are started by default.

### Consul Election Succeeded
For Consul to function, a leader for the Consul cluster must be elected. This
can be verified with the command:
```
sudo docker service logs voltha_consul 2>&1 | grep -i "New leader elected"
```

This command uses `grep` to search the logs of the Consul service logs for
the messages indicating a leader was elected. The output should be similar
to that below, including 3 messages, 1 for each member of the cluster.

```
voltha_consul.0.q96kfhmtzfzq@voltha3    |     2017/11/22 19:55:07 [INFO] consul: New leader elected: 527897706f6c
voltha_consul.0.hx5xjq0b93vb@voltha2    |     2017/11/22 19:55:07 [INFO] consul: New leader elected: 527897706f6c
voltha_consul.0.37w6rsazff2o@voltha1    |     2017/11/22 19:55:07 [INFO] consul: New leader elected: 527897706f6c
```

If there are not 3 messages similar to the above then the Consul cluster did
not initialize correctly and VOLTHA will not function.

### VOLTHA Core Communicating to Consul
The command `sudo docker service logs -f voltha_vcore` can be used to view
logs of the `vcore` (VOLTHA Core) service. The VOLTHA Core should be
displaying a lot of logs that are either the `DEBUG` or `INFO` level. while
there may be some `ERROR` level messages at the start of the log, there should
not be any continuing `ERROR` level messages.

There are `ERROR` level messages at the start as the VOLTHA Core re-tries to
connect to the other services that have not yet started as the VOLTHA system
coalesces.

### VOLTHA Health and Adapters
If the previous verification checks are working properly, the VOLTHA CLI can
be accessed via `ssh -p 5022 voltha@$HOSTNAME` with the password `admin` from
any of the VMs. Once at the CLI prompt. the following commands and output
should work:
```
ssh -p 5022 voltha@$HOSTNAME
```
```
Warning: Permanently added '[voltha1]:5022' (ECDSA) to the list of known hosts.
voltha@voltha1's password:
Welcome to Ubuntu 16.04.3 LTS (GNU/Linux 4.4.0-93-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

         _ _   _            ___ _    ___
__ _____| | |_| |_  __ _   / __| |  |_ _|
\ V / _ \ |  _| ' \/ _` | | (__| |__ | |
 \_/\___/_|\__|_||_\__,_|  \___|____|___|
(to exit type quit or hit Ctrl-D)
```

#### Health
```
(voltha) health
```
```
{
    "state": "HEALTHY"
}
```

#### Adapters
```
(voltha) adapters
```
```
Adapters:
+---------------+---------------------------+---------+
|            id |                    vendor | version |
+---------------+---------------------------+---------+
|    adtran_olt |              Adtran, Inc. |     0.9 |
|    adtran_onu |              Adtran, Inc. |     0.2 |
| asfvolt16_olt |                  Edgecore |     0.1 |
|  broadcom_onu |            Voltha project |     0.4 |
|      dpoe_onu |   Sumitomo Electric, Inc. |     0.1 |
|     maple_olt |            Voltha project |     0.4 |
| microsemi_olt |     Microsemi / Celestica |     0.1 |
|      pmcs_onu |                      PMCS |     0.1 |
|    ponsim_olt |            Voltha project |     0.4 |
|    ponsim_onu |            Voltha project |     0.4 |
+---------------+---------------------------+---------+
| simulated_olt |            Voltha project |     0.1 |
| simulated_onu |            Voltha project |     0.1 |
|     tibit_olt | Tibit Communications Inc. |     0.1 |
|     tibit_onu | Tibit Communications Inc. |     0.1 |
+---------------+---------------------------+---------+
```

#### Previson and Enable Sample OLT
```
(voltha) preprovision_olt
success (device id = 0003f9df83ef012f)
```
```
(voltha) enable
```
```
enabling 0003f9df83ef012f
waiting for device to be enabled...
success (logical device id = 0003000000000001)
```

#### List Devices
```
(voltha) devices
```
```
Devices:
+------------------+---------------+------+------------------+------+-------------------+-------------+-------------+----------------+----------------+-------------------------+--------------------------+
|               id |          type | root |        parent_id | vlan |       mac_address | admin_state | oper_status | connect_status | parent_port_no | proxy_address.device_id | proxy_address.channel_id |
+------------------+---------------+------+------------------+------+-------------------+-------------+-------------+----------------+----------------+-------------------------+--------------------------+
| 0003f9df83ef012f | simulated_olt | True | 0003000000000001 |      | 00:0c:e2:31:40:00 |     ENABLED |      ACTIVE |      REACHABLE |                |                         |                          |
| 000377079a992b07 | simulated_onu |      | 0003f9df83ef012f |  101 |                   |     ENABLED |      ACTIVE |      REACHABLE |              1 |        0003f9df83ef012f |                      101 |
| 000304183aede1d2 | simulated_onu |      | 0003f9df83ef012f |  102 |                   |     ENABLED |      ACTIVE |      REACHABLE |              1 |        0003f9df83ef012f |                      102 |
| 00034f07bb687281 | simulated_onu |      | 0003f9df83ef012f |  103 |                   |     ENABLED |      ACTIVE |      REACHABLE |              1 |        0003f9df83ef012f |                      103 |
| 00032277c82c563f | simulated_onu |      | 0003f9df83ef012f |  104 |                   |     ENABLED |      ACTIVE |      REACHABLE |              1 |        0003f9df83ef012f |                      104 |
+------------------+---------------+------+------------------+------+-------------------+-------------+-------------+----------------+----------------+-------------------------+--------------------------+
```
## Stopping VOLTHA
VOLTHA can be stopped by using the the command:
```
sudo docker stack rm voltha
```

After stopping VOLTHA, it is recommend you delete any persistent Consul
information before restarting VOLTHA (see **Troubleshooting -- Consul Not
Electing Leader**).
```
sudo docker stack rm voltha
# Wait for all containers to stop
sudo rm -rf /var/local/*

# You will be prompted for the password, ubuntu, when issuing the following
# commands
ssh ubuntu@172.42.43.102 'sudo rm -rf /var/local/*'
ssh ubuntu@172.42.43.103 'sudo rm -rf /var/local/*'
```

## VM Teardown
The VMs can be deleted using the following command on the same host,
in the same location in which the `vagrant up` command was executed.
```
vagrant destroy -f
```

## Troubleshooting

### Consul Not Electing Leader
The most common issue is Consul leadership election failing. This can happen
if the system is restarted as Consul just doesn't deal well with IP changes.

This issue can likely be fixed by deleting any Consul data stored locally and
restarting (`sudo docker stack deploy`) the system. To accomplish this issue
the following commands from the `voltha1` VM:

```
sudo docker stack rm voltha
# Wait for all containers to stop
sudo rm -rf /var/local/*

# You will be prompted for the password, ubuntu, when issuing the following
# commands
ssh ubuntu@172.42.43.102 'sudo rm -rf /var/local/*'
ssh ubuntu@172.42.43.103 'sudo rm -rf /var/local/*'
```

## Caveats

### Online Connectivity
This playground assume Internet access. Specifically, images must be
downloadable from `dockerhub.com`. There is **NO** local docker registry
deploy or utilized.

### NO Distributed, Persistent Filesystem
This playground is not backed by a distributed persistent filesystem, such as
is deployed in the default development deployment. Instead Consul data is
written to `/var/local` on each of the compute nodes.

## Advanced Topics

### Jinja2 and the Stack File
Included in this playground is a Docker Swarm Stack file
(`voltha-stack-3-masters.yml`). This file was generated using a `Jinja2`
(`http://jinja.pocoo.org/`) template file (`voltha-stack.yml.j2`), which
is also included in the playground.

Jinja2 was needed to generate this file because as of current stable Docker
version `17.09.0-ce` an environment variable cannot be used to set the number
of replicas for a services. The stack file varies the cardinality of
some of the service instances based on the number of Docker Swarm Manager
nodes. While this feature is supported in the `edge` version of Docker,
`17.11.0-ce`, the global deploy mode in this version seems to be incompatible
with the Consul docker image.

If you need to generate a Docker stack file that is compatible with a Docker
Swarm cluster that has a different number of master nodes the following
command can be used on the `voltha1` VM: (Be sure to replace `<#>` in the
below command with the number of Docker Swarm Managers in your cluster.)
```
sudo docker run -v /vagrant:/data -e SWARM_MANAGER_COUNT=<#> opencord/voltha-j2 /data/voltha-stack.yml.j2 > my-custom-stack.yml
```

This custom Docker Stack file can then be used with the `docker stack deploy`
command.

**NOTE:** This will go away once the Docker edge release becomes stable and
works.
