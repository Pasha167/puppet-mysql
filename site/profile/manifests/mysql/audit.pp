class profile::mysql::audit {	
    require profile::mysql
    include profile::base::syslog # needed for rsync restart

    # Installs and configures MariaDB audit plugin
    
    # Install plugin on database		  
    mysql_plugin { 'SERVER_AUDIT':
      ensure                   => 'present',
      soname                   => 'server_audit.so',
    }
->

    # Install bash script that configures audit plugin and update audit users list
    file { '/usr/local/bin/mysql_audit_users.sh':
        source               => "puppet:///modules/profile/mysql/mysql_audit_users.sh",
        mode                 => '0750',
        notify               => Exec['Update database audit settings'],
         }

    # Install cron to run bash script. 
    $cron_content='# MANAGED BY PUPPET. Update audit users list
MAILTO=user@domain.com
0 * * * * root /usr/local/bin/mysql_audit_users.sh
MAILTO=""
'
    file { "/etc/cron.d/mysql_audit":
             ensure            => present,
             content           => $cron_content,
    }

   # Send audit events to separate file
   $auditlogdir=hiera('profile::mysql::logdir')
   $rsyslog_content="# MANAGED BY PUPPET. MySQL audit
module(load=\"imfile\")
# MySQL Audit log file
input(type=\"imfile\"
      File=\"/opt/mysql/log/audit.log\"
      Tag=\"mysql:\"
      StateFile=\"mysql-audit\"
      Severity=\"notice\"
      Facility=\"local0\"
      PersistStateInterval=\"1000\")
local0.notice             @@logserver
local0.notice             stop"

    file { "/etc/rsyslog.d/mysql_audit.conf":
             ensure            => present,
             content           => $rsyslog_content,
             notify            => Service['rsyslog'],
             require           => File['/usr/local/bin/mysql_audit_users.sh'],
    }

       # Update database audit settings, notified by File['/usr/local/bin/mysql_audit_users.sh']
        exec { 'Update database audit settings':
          path            => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
          command         => '/usr/local/bin/mysql_audit_users.sh',
          logoutput       => true,
          refreshonly     => true,
          environment     => "HOME=${::root_home}",
          timeout         => 300,
        }

}
