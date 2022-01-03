# Ansible

Jump to:
[Commands recap](#Commands-recap)
<br>

1. [Interest](#Introduction)<br>
2. [Installation & configuration](#Installation)<br>
3. [Ad hoc commands](#TP3-ad-hoc-commands-for-package-installation )<br>
4. [Inventory](#Inventory-file)
5. [Playbooks](#Playbooks)
6. Templates, loop and condition (Jinja)
7. include, import, tags
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

## Inventory

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

# Inventory file
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

# Playbooks
In a manifest, it is possible to have several playbooks.

[Playbook keywords](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html)

Best practice: one playbook for one big action.

## Playbook pattern

https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html


`ansible-playbook`
```yaml
---
# Example

# Contains a list of playbooks, so with a -
-
  hosts: all
  vars:
    vars_file

  pre_tasks:
    -
  tasks:
    -
  post_taks:
    -

-
# enf of yaml
...
```

## Host patterns

<table>
<tr><td>Description</td><td>Pattern(s)</td><td>Targets</td>
</tr>
<tr><td>All hosts</td><td>all (or *)</td><td></td></tr>
<tr><td>One host</td><td>host1</td><td></td></tr>
<tr><td>Multiple hosts</td><td>host1:host2 or host1,host2</td><td></td></tr>
<tr><td>One group</td><td>webservers</td><td></td></tr>
<tr><td>Multiple groups</td><td>webservers:dbservers</td><td>all hosts in webservers and dbservers</td></tr>
<tr><td>Excluding groups</td><td>webservers:!france</td><td>all hosts in webservers except those in france</td></tr>
<tr><td>Groups intersection</td><td>webservers:&staging</td><td>all hosts in webservers that are in staging</td></tr>
</table>

```yaml
---
- name: "first dep"
  become: yes
  hosts: prod
  tasks:
    - name: "clean folder"
```

```
production
staging

group_vars/
    group1.yml
    group2.yml

group_vars/
    group1.yml
    group2.yml
```

## lint
```sh
# install ansible-lint
sudo pip3 install ansible-lint
```
## TP8 simple playbook
Simple playbook for nginx installation
[tp8 playbook](./tp8/nginx.yml)

`ansible-playbook -i prod.yml nginx.yml`

# Templating with Jinja
```yaml
tasks:
  - name: Ansible Jinja2
    debug:
      masg: >
            --== Ansible Jinja2 ex ==--

            {# comment -#}
            {% if ansible_hostname == "worker01" -%}
               It's worker 01
            {% endif %}
```

## TP9 TP10 nginx and templating
[tp9 playbook](./tp9/nginx_tmp.yml)
<br>
[tp9 sh template](./tp9/install_nginx.sh.j2)

`ansible-playbook -i prod.yml ngix_tpl.yml`

## TP11 templating and hostname

# Loop
```yaml
---
- hosts: all
  tasks:
    - name: create new users
      user:
        name: '{{ item }}'
        state: present

      loop:
        - john
        - mike
        - andrew
```

## with_items
```yaml
  - name:
    with_items:
      - client1
      - client2
    when: ansible_distribution == 'Centos'
```

## with_dict
```yaml
tasks:
  - name: creat users
    user:
      name: "{{ item.key }}"
      comment: "{{ item.velue.name }}"
    with_dict:
      bob:
        name: Bob Sinclar
      david:
        name: David Guetta
```

## TP12 loop and condition
[TP12 playbook](tp12.yml)

# Include, import and tags
https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_includes.html

* **include_tasks**: dynamic
* **import_tasks**: static
* **import_playbook**: static

`static`: applied at playbook load<br>
`dynamic`: applied during playbook execution

```yaml
---
- name: "install nginx"
  become: yes
  tasks:
    include_tasks: /home/ubuntu/nginx_template.yml
```

`nginx_template.yml`
```yaml
---
- name: "install nginx"
  package:
    name: nginx
    state: present

- name: "enable nginx"
  service:
    name: nginx
    enabled: yes
    state: started
```

## Tags
Tag playbook or task
Special tags:
* always
* never

```sh
ansible-playbook -i hosts.yml webapp.yml --tags nginx
ansible-playbook -i hosts.yml webapp.yml --skip-tags play1
```

## TP13 include_tasks
[TP13 main.yml](tp13.yml)<br>
[TP13 install.yml ](tp13.yml)

NOTE: could use `set_facts` in task to set variable

NOTE 2: `import_tasks` does not work with loop (in this case)

-------
`main.yml`
```yaml
...
  tasks:
    - name: install
      include_tasks: install.yml
      when: ansible_distribution == "Ubuntu"
      loop:
        - git
        - nginx
```
`install.yml`
```yaml
---
  - name: pkg install
    apt:
      name: "{{ item }}"
      state: present
```

## Docker module
The module `docker_container` requires pip and module install on remote machine
```yaml
    - name: install pip3
      apt:
        name: python3-pip
        state: present
      when: ansible_distribution == "Ubuntu"

    - name: install docker.py module
      pip:
        name: docker-py
        state: present
```

# SSH
* Connection with private key in command line or in yaml
```yaml
  vars:
    ansible_ssh_private_key_file: /home/ubuntu/chris.pem
```
## Ansible vault

## Ansible config file
`.ansible_config` or `$ANSIBLE_CONFIG`
* init format

```sh
ansible --version # show the config file
```

## TP15 use ansible vault
```yaml
ansible_password: "{{ ansible_vault_password }}"
```

`secrets.yml`
```yaml
ansible_vault_password: ubuntu
```
`ansible-vault encrypt secrets.yml`

playbook.yml (excerpt)
```yaml
var_files:
  - secrets.yml 
```
`ansible_cfg`
```
[privilege_escalation]
# ask password when sudo
become_ask_pass = true

[defaults]
ask_vault_pass = true
```

`ansible-playbook -i hosts.yaml test.yml`


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

# Lint
ansible-lint nginx.yml

# Playbook
ansible-playbook -i prod.yml nginx.yml
ansible-playbook -i prod.yml nginx.yml --private-key key.pem

# Tags
ansible-playbook -i hosts.yml webapp.yml --tags nginx
ansible-playbook -i hosts.yml webapp.yml --skip-tags play1

```

# Playbook excerpts
```yaml
  tasks:
 
    - name: copy website files
      git:
        repo: https://github.com/hexotic/static-website-example.git
        dest: /var/www/html/
        force: yes

    - name: "create index.html"
      copy:
        src: /home/ubuntu/static-website-example/
        dest: /var/www/html

    - name: "modify un fact"
      set_fact:
        ansible_hostname: "{{ hostname }}"
        env: foo
  
    - name: get docker script
      command: 'curl -fsSL https://get.docker.com -o get-docker.sh'

    - name: Download Install docker script
      get_url:
        url: "https://get.docker.com"
        dest: /home/ubuntu/get-docker.sh

    - name: run script to install docker
      command: "sh /home/ubuntu/get-docker.sh"

    - name: add ubuntu to group docker
      user:
        name: ubuntu
        append: yes
        groups:
          - docker
```