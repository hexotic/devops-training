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

# TP
## TP docker install
Use puppet forge to install:
* docker
* docker compose
* add user to group docker

https://forge.puppet.com/modules/puppetlabs/docker/readme

```docker.pp```
```ruby
node 'puppetslave' {
  # include 'docker' - modules are in the path

  class { 'docker':
    docker_users => ['centos'],
    version => 'latest',
  }

  class { 'docker::compose':
    ensure => present,
    version => '1.29.2',
  }
}
```

* Install on server
```puppet module install puppetlabs-docker --version 4.1.2```
* Add manifest
* on client: ```puppet agent --test```

## TP nginx
* Install nginx in a container on port 8090
```nginx.pp```
```ruby
node 'puppetslave' {

  docker::run { 'nginx8090':
    image            => 'nginx',
    extra_parameters => [ '--restart=always' ],
    ports            => ['8090:80'],
  }
}
```

## TP docker compose
```ruby

file { '/tmp/docker-compose.yml':
    ensure => file,
    content => '
version: "3.1"

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: exampleuser
      WORDPRESS_DB_PASSWORD: examplepass
      WORDPRESS_DB_NAME: exampledb
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:',
}

docker_compose { 'wordpress':
  compose_files => ['/tmp/docker-compose.yml'],
  ensure  => present,
}
```

## TP docker compose 2
Using a module

```sh
mkdir -p wordpress/{files,manifests,templates}
```

```
wordpress
├── files
│   └── docker-compose.yml
├── manifests
│   └── init.pp
└── templates
```

```wordpress/files/docker-compose.yml```
```yaml
version: "3.1"

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: exampleuser
      WORDPRESS_DB_PASSWORD: examplepass
      WORDPRESS_DB_NAME: exampledb
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:
```

```wordpress/manifests/init.pp```
```ruby
class wordpress {
  file { '/tmp/docker-compose.yml':
    source => 'puppet:///modules/wordpress/docker-compose.yml',
    ensure => file,
  }

  docker_compose { 'wordpress':
    compose_files => ['/tmp/docker-compose.yml'],
    ensure        => present,
  }
}
```

```production/wordpress.pp```
```ruby
include wordpress
```

# Puppet DB
Puppet board connects to Puppet DB (PostgreSQL 11)
https://puppet.com/docs/puppetdb/7/overview.html

```
/etc/hosts 127.0.0.1 puppetdb
```

### 01_install_docker.pp
```ruby
class { 'docker':
  docker_users => ['vagrant'],
}

class {'docker::compose':
  ensure => present,
}
```
```
puppet apply 01_install_docker.pp
```

### 02_postgres.pp
```ruby
docker::run { 'postgres':
  image            => 'postgres:11',
  ports            => '5432:5432',
  env              => ['POSTGRES_DB=puppetdb','POSTGRES_PASSWORD=puppetdb', 'POSTGRES_USER=puppetdb'],
}
```
```
puppet apply 02_postgres.pp
```

### 03_puppetdb.pp

```ruby
class { 'puppetdb::server':
  listen_address    => '0.0.0.0',
  open_listen_port  => 'true',
  listen_port       => '8080',
  database_host     => '127.0.0.1',
  database_port     => '5432',
  database_username => 'puppetdb',
  database_password => 'puppetdb',
  database_name     => 'puppetdb',
  read_database_username => 'puppetdb',
  read_database_password => 'puppetdb',
}
# Configure the Puppet master to use puppetdb
class { 'puppetdb::master::config': }
```
```sh
puppet module install puppetlabs-puppetdb --version 7.10.0
puppet apply 03_puppetdb.pp
systemctl status puppetdb
```

Puppet board: http://<ip>:8080

------
From there the install does not work
### 04_puppetboard.pp
```ruby
class { 'puppetboard':
  python_version  => '3.6',
  enable_catalog  => false,
}

python::pip { 'flask':
virtualenv => '/srv/puppetboard/virtenv-puppetboard',
}

class { 'apache': }
class { 'apache::mod::wsgi': }

class { 'puppetboard::apache::vhost':
  vhost_name => 'puppet.home',
  port       => 8888,
}
```

```
/etc/hosts
127.0.0.1 puppetdb puppet.home
```

```
puppet module uninstall --force puppetlabs-stdlib
puppet module install puppetlabs-stdlib --version 7.0.0
puppet module install puppet-puppetboard --version 8.0.0
puppet module install puppetlabs-apache --version 7.0.0
puppet module install puppet-python --version 6.2.1
puppet apply /root/puppetdb/04_puppetboard.pp
```

Go to http://<ip master>:8888
