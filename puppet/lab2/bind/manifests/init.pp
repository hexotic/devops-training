class bind {

  exec { 'yum update':
   command => '/usr/bin/yum update -y'
  }

  # Install DNS package
  package { 'bind':
    require => Exec['yum update'],
    ensure => installed
  }
  
  # Modify conf
  file { '/tmp/zone.txt':
    mode => "0640",
    source => 'puppet:///modules/bind/zone.txt',
    require => Package['bind'],
  }

  exec { 'Mod conf':
    command =>'cat /tmp/zone.txt >> /etc/named.conf',
    cwd     => '/etc/',
    path    => [ '/usr/bin', '/bin', ],
    require => Package['bind'],
  }

  # Copy zone data
  file { '/var/named/zone.chris.puppet':
    mode => "0640",
    owner => 'root',
    source => 'puppet:///modules/bind/zone.chris.puppet',
    require => Package['bind'],
  }

  # Start DNS service named from bind package
  service { 'named':
    enable => true,
    ensure => running,
    require => Package['bind'],
  }

}
