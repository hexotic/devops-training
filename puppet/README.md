# Puppet notes

Important components:
* facter: fetch machines information, run on the client and return a parit attribute/value (facts)
* puppetca: utility to approve client certificates

Puppet requires qualified machines. <br>
A certificate requires a FQDN

# Installation on AWS EC2

Note: Generic install (in French)
https://sysreseau.net/comment-installer-puppet-sur-redhat-centos-7/


## Beware of possible firewall and selinux
Firewall and selinux can block port used by puppet as well as connection to the internet.

<details>

<summary>
<b>Watch firewall</b>
</summary>

```sh
systemctl status firewalld
systemctl stop firewalld
systemctl disable firewalld
```

</details>

<details>

<summary>
<b>Watch selinux</b>
</summary>

```sh
/etc/selinux/config
vi /etc/sysconfig/selinux
Put disabled et REBOOT
```
</details>

## EC2 config (2 instances: server and client)
* AMI centos 7
* t3 small: 2 vpcu 2gi RAM 20 Gi DISK
* must open port 8140 in Security Group

### Host and hostname configuration (server and client)
```
# Change hostname (requires reboot)
sudo sh -c 'echo "chris-puppet-master" > /etc/hostname'
sudo reboot now
```
### Add server and client local IP to hosts
```sh
vim /etc/hosts
172.31.2.195 puppetmaster.chris.edu chris-puppet-master
172.31.8.219 puppetnode.chris.edu chris-puppet-node
```

# Puppet install : puppetserver for master, agent for master and slave

## Server install

```sh
# Server install
sudo rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
sudo yum update -y
sudo yum install -y puppetserver puppet-agent
```

### Change 2g to 512m (server)
```sh
cat /etc/sysconfig/puppetserver
JAVA_ARGS="-Xms512m -Xmx512m -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"

sudo systemctl enable --now puppetserver
```

If everything went correctly:
```
[centos@ip-172-31-2-195 ~]$ puppetserver -v 
puppetserver version: 7.5.0
```

## Client install

```sh
# Client install
sudo rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
sudo yum update -y
sudo yum install puppet-agent -y
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
```

-----------------------
# Puppet configuration
## On server

```sh
cat << EOF >> /tmp/puppet_srv_cfg.txt

[master]
dns_alt_names = chris-puppet-master

[main]
certname = chris-puppet-master
server = chris-puppet-master
environment = production
runinterval = 1h
EOF
sudo cat /tmp/puppet_srv_cfg.txt >> /etc/puppetlabs/puppet/puppet.conf
sudo systemctl restart puppetserver
```

## On client

```sh
cat << EOF >> /tmp/puppet_clt_cfg.txt
[main]
certname = chris-puppet-client
server = chris-puppet-master
environment = production
runinterval = 1h
EOF
sudo cat /tmp/puppet_clt_cfg.txt >> /etc/puppetlabs/puppet/puppet.conf
```

dns_alt_names : on veut eviter des requetes DNS.

# Certificates generation

## On server

```sh
[centos@chris-puppet-master ~]$ puppetserver ca setup
Generation succeeded. Find your files in /home/centos/.puppetlabs/etc/puppetserver/ca

sudo su -
puppetserver ca setup

[root@chris-puppet-master ~]# puppetserver ca list --all
Signed Certificates:
    ip-172-31-2-195.ec2.internal           (SHA256)  66:87:41:48:44:24:82:12:0F:EB:C2:22:B6:CA:0C:B0:6E:85:B8:A4:05:B8:4E:18:DB:51:C0:37:7D:8A:70:40	alt names: ["DNS:puppet", "DNS:ip-172-31-2-195.ec2.internal"]	authorization extensions: [pp_cli_auth: true]
    chris-puppet-master.ec2.internal       (SHA256)  BD:C6:18:67:B2:7C:D5:C0:25:73:0A:52:24:C8:EA:C1:5B:D3:85:FD:22:E7:5B:3A:61:56:56:22:12:E4:F4:BF	alt names: ["DNS:puppet", "DNS:chris-puppet-master.ec2.internal"]	authorization extensions: [pp_cli_auth: true]
    chris-puppet-master                    (SHA256)  1C:A1:D7:99:2C:38:41:FF:BA:B4:B6:A6:A8:86:3C:15:3C:F9:4A:3C:D7:E2:A4:DF:15:1C:5F:75:0C:93:96:C2	alt names: ["DNS:chris-puppet-master", "DNS:chris-puppet-master"]	authorization extensions: [pp_cli_auth: true]
```

## On client

```sh
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

--- srv apres client
[root@chris-puppet-master ~]# puppetserver ca list --all
Requested Certificates:
    chris-puppet-client       (SHA256)  26:D2:2A:2F:3E:91:F9:3C:A7:2C:52:85:C1:29:C6:97:8D:EF:D4:6E:5C:48:46:94:2A:87:58:CB:EE:32:A8:03
Signed Certificates:
```

## On server
```
puppetserver ca sign --certname chris-puppet-client
```

# Examples

Example 1
=====

``` /etc/puppetlabs/code/environments/production/manifests/site.pp```

```ruby
package { "openssh-server":
  ensure => installed
}

file { "/etc/ssh/sshd_config":
  path => "/etc/ssh/sshd_config",
  owner => root,
  group => root
  mode => 700,
  require => Package["openssh-server"],
  source => ["pupper:///ssh/sshd_config.${hostname}"],
}
```

Example 2
=====

```ruby
node 'chris-puppet-client' {

file { "/tmp/chris":

  ensure => 'directory',
  owner => 'root',
  group => 'root',
  mode => '0755',
}

group { 'usergrp':

  ensure => present,
  name => usergrp,
  gid => '1001'
}

user { 'chris':

  ensure => present,
  uid => '1001',
  gid => '1001',
  name => 'christophe',
  shell => '/bin/bash',
  home => '/home/chris',
}

}
```

## On client
Launch this command to execute puppet manifest:
```puppet agent --test```

# Modules

* puppet forge
* puppet module install puppetlabs-apache

module structure:
* manifests (.pp)
* files
* templates: erb format

manifests
```
lamp
├── files
├── manifests
│   └── init.pp 'class lamp { }'
└── templates
```
```
site.pp
node 'chris-puppet-client' {
  include lamp
}
```

/etc/puppetlabs/code/environments/production/modules

```
class ssh:install {
}
class ssh {
   include ssh::install
}
```