class profile::mysql($apt_repos, $apt_pins, $root_password) inherits profile::mysql::params {
if ($::operatingsystem == 'Debian') {
    # This is main class that installs and set basic conf for MySQL

    $logbindirectory=mysql_dirname($profile::mysql::params::override_options[mysqld][log_bin])
    # Create log directory, if log_bin is not set. Otherwise mysql module will create it automatically
    if $logbindirectory == '.' {
     file { [ hiera('profile::mysql::logdir') ]:
            ensure  => 'directory',
            owner   => 'mysql',
            group   => 'mysql',
            mode    => '0750',
     } 
    }


    create_resources(apt::source, $apt_repos)
    create_resources(apt::pin, $apt_pins)

    user {
        'mysql':
            ensure => present,
            system => true,
            shell  => '/bin/false',
    }
->
     file { [ hiera('profile::mysql::maindir'),
              "${profile::mysql::params::override_options[mysqld][datadir]}",
              "${profile::mysql::params::override_options[mysqld][tmpdir]}", ]:
            ensure  => 'directory',
            owner   => 'mysql',
            group   => 'mysql',
            mode    => '0750',
     }

->
#Installing MariaDB server and client using mysql puppet module.
# my.cnf is managed in profile::mysql::params
     class {'::mysql::client':
           package_name    => 'mariadb-client-10.1',
           package_ensure  => 'present',
           require => Class['apt::update'],
     }
->
     class {'::mysql::server':
           root_password           => $root_password,
           remove_default_accounts => true,
           package_name            => 'mariadb-server-10.1',
           config_file             => '/etc/mysql/my.cnf',
           manage_config_file      => false,
           override_options        => $profile::mysql::params::override_options,
           service_manage          => false,
           users                  => {
           'admin@%'      => {
              ensure                  => 'present',
              password_hash           => '*xxx',
             },

           },
           grants                 => {
            'admin@%/*.*'           => {
              ensure                   => 'present',
              privileges               => ['SELECT', 'PROCESS', 'LOCK TABLES', 'REPLICATION SLAVE', 'REPLICATION CLIENT', 'SHOW VIEW', 'TRIGGER'],
              table                    => '*.*',
              user                     => 'admin@%',
             },

           },
        }
# Installing SYS schema (adopted for MariaDB version)
->
    file { '/opt/mysql/tmp/sys_1.5.1_56_inline.sql':
       source         => 'puppet:///modules/profile/mysql/sys_1.5.1_56_inline.sql',
         }
->
    exec { 'mysql < /opt/mysql/tmp/sys_1.5.1_56_inline.sql':
      path            => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      logoutput       => true,
      refreshonly     => false,
      environment     => "HOME=${::root_home}",
      unless          => 'mysql -BN -e"show databases" | grep "^sys$"',
      timeout         => 300,
    }
->    
# Installing additional MySQL tools
      package { 'percona-toolkit':
        ensure => 'present',
      }
->
      file { '/usr/bin/mysqltuner.pl':
                source                   => 'puppet:///modules/profile/mysql/mysqltuner.pl',
      }
->
      file { '/usr/bin/mysqldumpsplitter.sh':
                source                   => 'puppet:///modules/profile/mysql/mysqldumpsplitter.sh',
      }   
->
      file { '/etc/cron.d/mysql':
                ensure                    => present,
       }
 }
}
