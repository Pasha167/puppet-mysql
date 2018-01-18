#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

##############################################################################
## Information                                                              ##
##############################################################################
# MANAGED BY PUPPET!!!!
# For support please contact DBAs at dba@flowtraders.com.
# 
# This script will update the list of users that must be excluded from auditing

# Exit, if mysql is not running
pgrep mysqld >> /dev/null || exit 0

# Check the audit logs growing rate and signal, if faster then 100Mb per 600 sec
if [ -e /opt/mysql/log/audit.log.1 -a -e /opt/mysql/log/audit.log.2 ]
then
    diff=$((`stat --printf '%Y' /opt/mysql/log/audit.log.1` - `stat --printf '%Y' /opt/mysql/log/audit.log.2`))
    if [ $diff -lt 600 ]
    then
       echo "MySQL audit logs (/opt/mysql/log/audit.log*) are growing to fast: around 100MB per $diff secs. Check and exclude some application users."
    fi
fi

# Check if audit config file is there
if [ ! -w /etc/mysql/conf.d/audit.cnf ]
then 
audit_params="# MANAGED BY PUPPET. MySQL audit
[mysqld]
server_audit_excl_users=svc_test,app_test
server_audit_events='CONNECT,QUERY'
server_audit_file_path='/opt/mysql/log/audit.log'
server_audit_file_rotate_size=100000000
server_audit_query_log_limit=2048
server_audit_logging=1"

mysql -e"SET GLOBAL server_audit_output_type='file',
server_audit_excl_users='svc_test,app_test',
server_audit_events='CONNECT,QUERY',
server_audit_file_path='/opt/mysql/log/audit.log',
server_audit_file_rotate_size=100000000,
server_audit_query_log_limit=2048,
server_audit_logging=1;"

echo "$audit_params" > /etc/mysql/conf.d/audit.cnf
fi

# Get current list
server_audit_excl_users_ori=$(grep server_audit_excl_users /etc/mysql/conf.d/audit.cnf | cut -d"=" -f 2 | tr -d '[:space:]')
server_audit_excl_users_ori=${server_audit_excl_users_ori//,/ }

# Generate the list of users to exclude from database
server_audit_excl_users_upd=$(mysql -NB -e"
select group_concat( distinct user separator ' ')
  from mysql.user
 where user like 'app\_%'
    or user like 'svc\_%'
 order by user;"
                            )

# Merge two user lists and remove duplicates
server_audit_excl_users_new=$(echo $server_audit_excl_users_upd $server_audit_excl_users_ori | tr ' ' '\n' | sort -u | xargs)

if [ "$server_audit_excl_users_ori" != "$server_audit_excl_users_new" ]
 then
      # Create comma-separated list of users
      users=$(echo $server_audit_excl_users_new | tr ' ' ',')
      # Update the excl list of users in database:
      mysql -e"SET GLOBAL server_audit_excl_users='$users';"

      server_audit_excl_users_new=server_audit_excl_users=$users
      # Update the excl list of users in config file:
      sed -i "s/.*server_audit_excl_users.*/$server_audit_excl_users_new/" /etc/mysql/conf.d/audit.cnf
fi

