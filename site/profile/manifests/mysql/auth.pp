class profile::mysql::auth($svc_mysql_password, $dbadmins) {	
    require profile::mysql 
    
    # Installs and configures MariaDB AD authentication plugin
    $keytab='/etc/krb5mariadb.keytab'
    $upcase_domain=upcase("${::domain}")
    $princname="mariadb/${::fqdn}@${upcase_domain}"

    # Installing server side and client side dlls
    package { ['mariadb-gssapi-client-10.1', 'mariadb-gssapi-server-10.1']:
              ensure                   => 'present',
              require                  => Class['apt::update'],
    }
->
    # Creating service principal and extracting keytab
    exec { "Creating service principal and extracting keytab":
	      command     => "net ads keytab add mariadb -U 'admin'%'${svc_mysql_password}'",
	      path        => '/usr/bin:/usr/sbin:/bin',
	      environment => [ "KRB5_KTNAME=FILE:${keytab}" ],
	      unless      => "test -f ${keytab}",
    }    
->    
    # Change permissions for new plugin
    file { "${keytab}":
             owner             => 'mysql',
	     group             => 'mysql',
    }
->
    # Add my.cnf parameters
    
    file { "/etc/mysql/conf.d/auth.cnf":
             ensure            => present,
             content           => "[mysqld]\ngssapi-keytab-path=${keytab}\ngssapi-principal-name=${princname}",

    } 					     
->
    # Installing server side plugin on database
    mysql_plugin { 'gssapi':
      ensure                   => 'present',
      soname                   => 'auth_gssapi.so',
    }
->
   # Add/change DBAs to authenticate via new plugin. DB Admins are set in Hiera
    mysql_user{ $dbadmins:
       ensure                   => 'present',
       plugin                   => 'gssapi',
    }
    
    $dbadmins.each |String $dbadmin| {
       mysql_grant{ "${dbadmin}/*.*":
         ensure                   => 'present',
         options                  => ['GRANT'],
         privileges               => ['ALL'],
         table                    => '*.*',
         user                     => "${dbadmin}",
         require                  => Mysql_user["${dbadmin}"],
       }
    }
       
    # Updating keytab.  Runs only if keytab was updated by re-joining to Domain
    exec { "Updating keytab":
              command     => "net ads keytab add mariadb -P",
              path        => '/usr/bin:/usr/sbin:/bin',
              environment => [ "KRB5_KTNAME=FILE:${keytab}" ],
              refreshonly => true,
              subscribe   => Exec['join to AD'],
    }


}
