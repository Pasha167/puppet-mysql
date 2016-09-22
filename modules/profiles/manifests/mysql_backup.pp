class profiles::mysql_backup {

$entity=split($::domain,'\.') # get nl,sg or us

file { '/root/.ssh':
   ensure                   => directory,
   owner                    => 'root',
   group                    => 'root',
   mode                     => '0700',
}

file { '/root/.ssh/nllinux-backup-mysql.key':
   source                   => "puppet:///modules/profiles/${entity[0]}linux-backup-mysql.key",
   mode                     => "0600",
   require                  => File ['/root/.ssh'],
}

file { '/usr/bin/mysqlbackup':
   source                   => "puppet:///modules/profiles/mysqlbackup",
   mode                     => "0750",
}

# Backup dir will be created automatically by backup script

# class {'mysql::server::backup':
#  backupuser              => 'backup',
#  backuppassword          => 'aaa', # hash is not working
#  backupdir               => '/opt/dumps/backup/',
#  file_per_database       => true,
#  include_routines        => true,
#  include_triggers        => true,
#  time                    => ['11','00'],
#  provider                => 'mysqldump',
# }
}
