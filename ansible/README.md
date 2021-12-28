# Ansible

Jump to:
[Commands recap](#Commands-recap)
<br>

1. [Interest](#Introduction)<br>
2. [Installation & configuration](#Installation)<br>
3. [Ad hoc commands](#TP3-ad-hoc-commands-for-package-installation )<br>
4. [Inventory](#Inventory)
5. Playbook
6. Templates (Jinja)
7. include, import tags
8. security (sensitive variables)
9. Tower

# Introduction
## Advantages
* free & opensource
* powerful
* flexible
* secure
* idempotent
* **agentless** (Requires python and ssh)

Can be used for tests and deployment:
* cloud provisioner
* configuration mngt
* app deployment

### IaC tools

* configuration mngt: ansible, puppet, saltstack
* server templating: docker, packer, vagrant
* provisionning tools: terraform, cloud formation

## Components
* executable (ansible binary)
* inventory
* modules
  * https://docs.ansible.com/ansible/latest/collections/index_module.html
  * https://github.com/ansible/ansible-modules-core
* playbook


### Modules
* setup module
* file module
* copy module
* command module
* colour codes : 
  * red: failure
  * yellow: success with changes
  * green: success with no change
* doc with : ```ansible-doc```

# Installation

Method 1 - stable version of ansible
* apt-get / yum install

Method 2 - install a more recent version
* pip install

## Configuration

* ```/etc/ansible/ansible.cfg``` : default behaviours
* ```~/.ansible.cfg```
* ```./ansible.cfg``` : project dir
* env variable ```ANSIBLE_CONFIG```
  * ```export ANSIBLE_CONFIG=file.cfg```

`ansible --version` : allows to know which conf file is used.

## TP0 installation on AWS EC2
* t3.medium - ubuntu - ansibleMaster
* t2.micro x 2 - ubuntu - ansibleWorker0[12]
* user: ubuntu (not root)
* install with pip3
```sh
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install ansible
```

<details>

<summary><code>ansible --version</code>
</summary>

```sh
ansible [core 2.12.1]
  config file = None
  configured module search path = ['/home/ubuntu/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/lib/python3.8/dist-packages/ansible
  ansible collection location = /home/ubuntu/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/local/bin/ansible
  python version = 3.8.10 (default, Nov 26 2021, 20:14:08) [GCC 9.3.0]
  jinja version = 2.10.1
  libyaml = True
  ```

  </details>


## First commands: Ad-Hoc commands
Execute actions on distant hosts.

Example: <br>
`ansible webserver -m yum -a "name=httpd state=latest"`
`ansible <hosts> <module> <params>`

# Inventory

`Host file - example with password (not secure)`
```sh
172.31.86.191 ansible_user=ubuntu ansible_password=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no'
172.31.88.69  ansible_user=ubuntu ansible_password=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

```sh
# example ping
ansible -i hosts all -m ping
```

## Setting a ssh connection with password
```sh
# Change setting on clients /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Restart ssh service
sudo systemctl restart ssh
# Change ubuntu user password
sudo -i passwd ubuntu
```
```sh
# Install sshpass on master
sudo apt-get install -y sshpass
```

<details>
<summary> <code>ansible -i hosts all -m ping</code>
</summary>

```sh
172.31.88.69 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
172.31.86.191 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

</details>

<details>
<summary>inventory with alias
</summary>

```sh
worker01 ansible_host=172.31.86.191 ansible_user=ubuntu ansible_password=Chris ansible_ssh_common_args='-o StrictHostKeyChecking=no'
worker02 ansible_host=172.31.88.69  ansible_user=ubuntu ansible_password=Chris ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```
</details>


## Example 2: create file on one worker
<details>
<summary><code>
ansible -i hosts worker01 -m copy -a "dest=/home/ubuntu/chris.txt content='Bonjour World'"
</code>
</summary>

```sh
worker01 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": true,
    "checksum": "734eadc564c754fe2c717267fd8096bd55a38d4e",
    "dest": "/home/ubuntu/chris.txt",
    "gid": 1000,
    "group": "ubuntu",
    "md5sum": "09a2bf32e15f5cd28ccf20e401d9c970",
    "mode": "0664",
    "owner": "ubuntu",
    "size": 13,
    "src": "/home/ubuntu/.ansible/tmp/ansible-tmp-1640689049.7857008-18863-270831475913922/source",
    "state": "file",
    "uid": 1000
}
```

</details>


## TP3 ad-hoc commands for package installation
NOTE: use `-b` for become (root)

```sh
# Install nginx on server 1
ansible -i hosts worker01 -b -m apt -a "name=nginx state=present"
ansible -i hosts worker01 -b -m service -a "name=nginx state=started enabled=yes"

# Install apache on server 2
ansible -i hosts worker02 -b -m apt -a "name=apache2 state=present"
ansible -i hosts worker02 -b -m service -a "name=apache2 state=started enabled=yes"

# Remove nginx on server 1
ansible -i hosts worker01 -b -m apt -a "name=nginx state=absent purge=yes autoremove=yes"

# Remove apache on server 2
ansible -i hosts worker02 -b -m apt -a "name=apache2 state=absent purge=yes autoremove=yes"
```

# Inventory
* format ini, yaml, json (`.yml` or `.yaml`)

## TP4 - yaml example
`hosts.yml`
```yaml
all:
  hosts:
    worker01:
      ansible_host: 172.31.86.191
      ansible_user: ubuntu
      ansible_password: Chris
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

    worker02:
      ansible_host: 172.31.88.69
      ansible_user: ubuntu
      ansible_password: Chris
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
```

## INI and YAML Format

<details>

<summary><code>ini example</code></summary>

```ini
[all:vars]
ansible_connection=local

[apache]
rec-apache-1 apache_url=rec.wiki.localdomain

[mysql]
...

[linux:children]
apache
mysql
```

</details>

<details>

<summary><code>yaml equivalent</code></summary>

```ini
all:
  vars:
    ansible_connection: local

linux:
  children:
    apache:
      hosts:
        rec-apache-1:
          apache_url: rec.wiki.localdomain

    mysql:
      hosts:
        ...
```

</details>

## Variables
* all: all groups
* hosts
* children: sub groups
* vars
* vars_files: file containing variables
* vars_prompt


##  TP5 - setup module
(repeat of what was done before)

## Variable override

Override in increasing priority:
[more here](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)

* group variables, file `host`
* group variables, file `group_vars`
* machine variables, file `host`
* machine variables, file `host_vars`
* variable in a YAML file `-e @file.yml`
* variable passed to Ansible `-e variable=value`

## Ansible inventory
```ansible-inventory -i hosts.yml --host worker02```

## TP6 - inventory and variable
`hosts.ini`
```
[all:vars]
ansible_user=ubuntu

[ansible]
localhost ansible_connection=local

[prod:vars]
env=production

[prod]
worker01 ansible_host=172.31.86.191 ansible_password=Chris ansible_ssh_common_args='-o StrictHostKeyChecking=no'
worker02 ansible_host=172.31.88.69  ansible_password=Chris ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

## TP 7 - inventory and variable override
```
├── group_vars
│   └── prod.yml  -> env: prod
├── host_vars
│   ├── worker01.yml  -> env: prod_host_1
│   └── worker02.yml  -> env: prod_host_2
├── hosts.yml
└── hosts.ini
```
```sh
ansible -i hosts.ini all -m debug -a "msg={{ env }}"
```
<details>
<summary>Output
</summary>

```
worker01 | SUCCESS => {
    "msg": "prod_host_1"
}
worker02 | SUCCESS => {
    "msg": "prod_hots_2"
}
```

</details>

------

# Commands recap

```sh
# Ping
ansible -i hosts.yaml all -m ping

# Install / remove
ansible -i hosts worker01 -b -m apt -a "name=nginx state=present"
ansible -i hosts worker01 -b -m service -a "name=nginx state=started enabled=yes"
ansible -i hosts worker01 -b -m apt -a "name=nginx state=absent purge=yes autoremove=yes"

# Create file on worker
ansible -i hosts.yml worker01 -m copy -a "dest=/home/ubuntu/chris.txt content='Bonjour World'"

# Get setup
ansible -i hosts.yml worker01 -m setup | grep -i hostname

# Debug - won't work since there is no action being executed
ansible -i hosts.yml worker01 -m debug -a "msg={{ ansible_hostanme }}"
ansible -i hosts.yml all -m debug -a "msg={{ env }}"

# Ansible Inventory
ansible-inventory -i hosts.yml --host worker01 # json format
ansible-inventory -i hosts.yml --list -y  # yaml format

```