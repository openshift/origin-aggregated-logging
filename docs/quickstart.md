# Quick Start to Deploy Logging

Following are instructions to standing up the logging stack.  Additional
parameterization to further customize and alter the deployment can be found
in the [openshift_logging role](https://github.com/openshift/openshift-ansible/tree/master/roles/openshift_logging).  

## Ansible Setup
These instructions assume you are familiar with Ansible and have met the minimal [installation requirements](http://docs.ansible.com/ansible/intro_installation.html) for the control machine and managed nodes.
1. `git clone https://github.com/ansible/ansible`
2. `cd ansible && git checkout v2.2.3.0-1`
3. `source hacking/env-setup`

## Deploy Aggregated Logging

1. Clone the Openshift installer
```
git clone https://github.com/openshift/openshift-ansible.git
```

2. Create an inventory file and set the first master IP ($HOST_IP) or machine name.

```
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_user=root
ansible_ssh_user=vagrant
ansible_ssh_private_key_file=/home/$USER/.ssh/.ssh/id_rsa
ansible_become=true

openshift_deployment_type=origin

openshift_logging_kibana_hostname=kibana.$HOST_IP.xip.io

[masters]
$HOST_IP

[nodes]
$HOST_IP
```
**Note:** An example of a more detailed inventory file for a complete Openshift cluster can be seen [here](https://github.com/openshift/openshift-ansible/blob/master/inventory/byo/hosts.origin.example).

3. Log into the machine defined by `nodes` with `ansible_ssh_user` to confirm this user can access the master node.
4. While on `master` log into the cluster as a user who has `cluster-admin` privileges.
3. From your control node:

```
ansible-playbook -i $INVENTORY_FILE -vv playbooks/byo/openshift-cluster/openshift-logging.yml
```
**Note:** Depending upon how the Openshift cluster is installed, you may or may not see a similiar error to the following in the Ansible output:
```
RUNNING HANDLER [openshift_logging : restart master] ***************************
fatal: [127.0.0.1]: FAILED! => {
    "changed": false,
    "failed": true
}

MSG:

Could not find the requested service "'origin-master'":

```

This message may be ignored.  You may now log in and confirm your deployment:

```
$ oc project openshift-logging # if that project doesn't exist, use logging
$ oc get pods
NAME                          READY     STATUS    RESTARTS   AGE
logging-curator-13-kbdj0      1/1       Running   1          1d
logging-es-295zi3tl-6-5jlb2   1/1       Running   1          1d
logging-fluentd-z6czf         1/1       Running   1          1d
logging-kibana-7-cx7w7        2/2       Running   2          18h
```

## Undeploy Aggregated logging
```
ansible-playbook -i $INVENTORY_FILE -vv playbooks/byo/openshift-cluster/openshift-logging.yml openshift_logging_install_logging=false
```
