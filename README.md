# puppet-mysql
Puppet manifests for Mariadb10.1

Deabian8 version.
Uses Hiera and Hiera-yaml (https://github.com/TomPoulton/hiera-eyaml):
gem install hiera-eyaml (/opt/puppetlabs/puppet/bin/gem install hiera-eyaml for puppet4)
eyaml createkeys
chown -R puppet:puppet /etc/puppet/keys/
chmod -R 0500 /etc/puppet/keys/
chmod 0400 /etc/puppet/keys/*.pem

cd /etc/puppet
eyaml edit /etc/puppet/hiera/common.eyaml
add: profiles::mysql_config::password: DEC::PKCS7[aaa]!


clear all:

systemctl stop mysql && apt-get remove --purge percona-toolkit mariadb-client-10.1 mariadb-server-10.1 mariadb-server-core-10.1 mariadb-common mysql-common mariadb-client-core-10.1 libmariadbclient18 galera-3 && rm -rf /etc/mysql/ /root/.my.cnf /etc/apt/sources.list.d/mariadb.list /etc/apt/sources.list.d/percona.list /var/lib/mysql/ /opt/mysql/ /etc/my.cnf /var/log/mysql && userdel mysql && apt-key del 1BB943DB && apt-key del CD2EFD2A

puppet apply --test -e 'include profiles::mysql_server'

Using $override_options as hash in hiera does not work well, when merge is needed. There is a need to use deeper merger (special gem). So simple string lookup is more reliable.


Module Fundamentals: https://docs.puppet.com/puppet/latest/reference/modules_fundamentals.html

my_module — This outermost directory’s name matches the name of the module.

    manifests/ — Contains all of the manifests in the module.
        init.pp — Contains a class definition. This class’s name must match the module’s name.
        other_class.pp — Contains a class named my_module::other_class.
        my_defined_type.pp — Contains a defined type named my_module::my_defined_type.
