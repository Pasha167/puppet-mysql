class profile::mysql::params {

# Get my.cnf options from hiera common.yaml using deeper_merge
$hiera_options = hiera_hash(profile::mysql::params::options)

# Calculate server_id
$ip=split($::ipaddress,'\.')
case size($ip) {
  4:       { $tmp_server_id="${ip[2]}${ip[3]}" }
  default: { $tmp_server_id=999999 }
}

# Calculate innodb buffer pool size and instances
$ibps=$hiera_options[mysqld][innodb_buffer_pool_size]
if size($ibps) == 0 {
   $tmp_size=floor(($::memorysize_mb-2000)/1.2)
   if $tmp_size < 100 {
     $tmp_innodb_buffer_pool_size = "128M"
     $tmp_innodb_buffer_pool_instances = 1
   }
   else {
     $tmp_innodb_buffer_pool_size="${tmp_size}M"
     $tmp_innodb_buffer_pool_instances=8
   }
}
else {
   $tmp_innodb_buffer_pool_size=$ibps
   $tmp_innodb_buffer_pool_instances=$hiera_options[mysqld][innodb_buffer_pool_instances]
}

$changed_options = {
   'mysqld'             => {
     'server_id'                             => "${tmp_server_id}",
     'innodb_buffer_pool_size'               => "${tmp_innodb_buffer_pool_size}",
     'innodb_buffer_pool_instances'          => "${tmp_innodb_buffer_pool_instances}",
   },
}

# Owerwrite my.cnf options from hiera with calculated values
$options = deep_merge($hiera_options, $changed_options)

# Set this for puppetlabs/mysql module to avoid default installation to /var/lib/mysql 
$override_options = $options 

file {
        '/etc/mysql/my.cnf':
            content => template("profile/my.cnf.erb"),
    }

}

