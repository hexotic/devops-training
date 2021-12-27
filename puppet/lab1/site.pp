node 'chris-puppet-client' {

  exec { 'yum update':
   command => '/usr/bin/yum update -y'
  }

  package { 'epel-release':
    require => Exec['yum update'],
    ensure => installed
  }

  package { 'httpd':
    require => Exec['yum update'],
    ensure => installed
  }

  service { 'httpd':
    ensure => running
  }

  package { 'mariadb-server':
    require => Exec['yum update'],
    ensure => installed
  }

  service { 'mariadb':
    ensure => running
  }

  package { 'php':
    require => Exec['yum update'],
    ensure => installed
  }

  file { '/var/www/html/index.php':
    notify => Service['httpd'],
    ensure => file,
    content => '<?php phpinfo();?>',
    require => Package['httpd']
  }
}
