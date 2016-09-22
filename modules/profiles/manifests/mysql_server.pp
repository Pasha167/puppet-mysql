class profiles::mysql_server {
if ($::operatingsystem == 'Debian') {

include profiles::mysql_config
include profiles::mysql_repositories
include profiles::mysql_backup

    user {
        'mysql':
            ensure => present,
            system => true,
            shell  => '/bin/false',
    }
->
#     file { ['/opt/mysql/data','/opt/mysql/tmp', '/opt/mysql/log']:
     file { ['/opt/mysql', '/opt/mysql/data','/opt/mysql/tmp']:
            ensure  => 'directory',
            owner   => 'mysql',
            group   => 'mysql',
            mode    => '0750',
            before => Package ['mariadb-server-10.1']
     }

->
     class {'::mysql::server':
           root_password         => hiera('profiles::mysql_config::password'),
           remove_default_accounts => true,
           package_name            => 'mariadb-server-10.1',
           config_file            => '/etc/mysql/my.cnf',
           purge_conf_dir         => true,
           override_options       => $profiles::mysql_config::override_options,
           includedir             => '',
           require                => Class['apt::update'],
           users                  => {
            'monyog@%'              => {
              ensure                  => 'present',
              password_hash           => '*A02AA727CF2E8C5E6F07A382910C4028D65A053A',
             },
           'root@%'                 => {
              ensure                  => 'present',
              password_hash           => '*A02AA727CF2E8C5E6F07A382910C4028D65A053A',
             },
           'nagios@%'               => {
              ensure                  => 'present',
              password_hash           => '*A02AA727CF2E8C5E6F07A382910C4028D65A053A',
             },
           'repl_slave@%'           => {
              ensure                  => 'present',
              password_hash           => '*A02AA727CF2E8C5E6F07A382910C4028D65A053A',
             },

           },
           grants                 => {
            'monyog@%/*.*'           => {
              ensure                   => 'present',
              privileges               => ['SELECT', 'RELOAD', 'PROCESS', 'SUPER'],
              table                    => '*.*',
              user                     => 'monyog@%',
             },
            'root@%/*.*'             => {
              ensure                   => 'present',
              privileges               => ['ALL'],
              table                    => '*.*',
              user                     => 'root@%',
              options                  => ['GRANT'],
             },
            'nagios@%/*.*'           => {
              ensure                   => 'present',
              privileges               => ['SELECT', 'REPLICATION CLIENT'],
              table                    => '*.*',
              user                     => 'nagios@%',
             },
            'repl_slave@%/*.*'           => {
              ensure                   => 'present',
              privileges               => ['REPLICATION SLAVE'],
              table                    => '*.*',
              user                     => 'repl_slave@%',
             },

           },
        }

->
    package { 'percona-toolkit':
        ensure                       => 'present',
  }

->

     file { [ '/etc/mysql/my.cnf.dpkg-dist','/etc/mysql/conf.d']:
            ensure                  => absent,
            force                   => true,
          }


}
}

