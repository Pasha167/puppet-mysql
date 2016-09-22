class profiles::mysql_config {

# Calculate server_id
$ip=split($::ipaddress,'\.')
case size($ip) {
  4:       { $server_id="${ip[2]}${ip[3]}" }
  default: { $server_id=999999 }
}

# Calculate innodb buffer pool size and instances
$ibps=hiera('profiles::mysql_config::innodb-buffer-pool-size')
if size($ibps) == 0 {
   $tmp_size=floor($::memorysize_mb*0.8/1024)
   if $tmp_size < 1 {
     $innodb_buffer_pool_size = "256M"
     $innodb_buffer_pool_instances = 2
   }
   elsif $tmp_size > 20 {
     $innodb_buffer_pool_size="${tmp_size}G"
     $innodb_buffer_pool_instances=10
   }
   else {
     $innodb_buffer_pool_size="${tmp_size}G"
     $innodb_buffer_pool_instances=ceiling("${tmp_size}"/2)
   }

}
else {
   $innodb_buffer_pool_size=$ibps
   $innodb_buffer_pool_instances=hiera('profiles::mysql_config::innodb_buffer_pool_instances')
}

 $override_options = {
  'client' => {
    'port'                                       => '3306',
    'socket'                                     => hiera('profiles::mysql_config::socket'),
  },

  'mysqldump' => {
       'max_allowed_packet'                      => 1G,
       'quick'                                   => undef,
       'quote-names'                             => undef,
   },

  'isamchk'                                      => undef,
  'mysqld_safe'                                  => undef,
  'mysqld-5.0'                                   => undef,
  'mysqld-5.1'                                   => undef,
  'mysqld-5.5'                                   => undef,
  'mysqld-5.6'                                   => undef,
  'mysqld-5.7'                                   => undef,

  'mysqld' => {
      'skip-external-locking'                    => undef,
      'ssl'                                      => undef,
      'ssl-ca'                                   => undef,
      'ssl-cert'                                 => undef,
      'ssl-key'                                  => undef,
      'thread-stack'                             => undef,

    # GENERAL #
      'user'                                     => hiera('profiles::mysql_config::user'),
      'default-storage-engine'                   => hiera('profiles::mysql_config::default-storage-engine'),
      'character-set-server'                     => hiera('profiles::mysql_config::character-set-server'),
      'collation_server'                         => hiera('profiles::mysql_config::collation_server'),
      'tmpdir'                                   => hiera('profiles::mysql_config::tmpdir'),
      'bind-address'                             => hiera('profiles::mysql_config::bind-address'),

    # MyISAM #
     'key-buffer-size'                           => hiera('profiles::mysql_config::key-buffer-size'),
     'myisam-recover'                            => hiera('profiles::mysql_config::myisam-recover'),

    # SAFETY #
     'max-allowed-packet'                        => hiera('profiles::mysql_config::max-allowed-packet'),
     'max-connect-errors'                        => hiera('profiles::mysql_config::max-connect-errors'),
     'sysdate-is-now'                            => hiera('profiles::mysql_config::sysdate-is-now'),
     'innodb-strict-mode'                        => hiera('profiles::mysql_config::innodb-strict-mode'),

    # DATA STORAGE #
     'datadir'                                   => hiera('profiles::mysql_config::datadir'),

    # BINARY LOGGING #
     'binlog-format'                             => hiera('profiles::mysql_config::binlog-format'),
     'expire-logs-days'                          => hiera('profiles::mysql_config::expire-logs-days'),
     'log-bin'                                   => hiera('profiles::mysql_config::log-bin'),
     'log-bin-index'                             => hiera('profiles::mysql_config::log-bin-index'),
     'sync-binlog'                               => hiera('profiles::mysql_config::sync-binlog'),
     'log_bin_trust_function_creators'           => hiera('profiles::mysql_config::log_bin_trust_function_creators'),
     'server-id'                                 => $server_id,
     'log-slave-updates'                         => hiera('profiles::mysql_config::log-slave-updates'),
     'max-binlog-size'                           => hiera('profiles::mysql_config::max-binlog-size'),

    # SLAVE #
     'slave-parallel-threads'                    => hiera('profiles::mysql_config::slave-parallel-threads'),
     'slave_max_allowed_packet'                  => hiera('profiles::mysql_config::slave_max_allowed_packet'),
     'relay-log'                                 => hiera('profiles::mysql_config::relay-log'),
     'relay-log-index'                           => hiera('profiles::mysql_config::relay-log-index'),

    # CACHES AND LIMITS
     'tmp-table-size'                             => hiera('profiles::mysql_config::tmp-table-size'),
     'max-heap-table-size'                        => hiera('profiles::mysql_config::max-heap-table-size'),
     'query-cache-type'                           => hiera('profiles::mysql_config::query-cache-type'),
    #'query_cache_limit'                         => hiera('profiles::mysql_config::query_cache_limit'),
     'query-cache-size'                           => hiera('profiles::mysql_config::query-cache-size'),
     'max-connections'                            => hiera('profiles::mysql_config::max-connections'),
     'thread-cache-size'                          => hiera('profiles::mysql_config::thread-cache-size'),
     'table-open-cache'                           => hiera('profiles::mysql_config::table-open-cache'),
     'table-definition-cache'                     => hiera('profiles::mysql_config::table-definition-cache'),
     'open-files-limit'                           => hiera('profiles::mysql_config::open-files-limit'),

    # INNODB #
     'innodb-flush-method'                        => hiera('profiles::mysql_config::innodb-flush-method'),
     'innodb-flush-log-at-trx-commit'             => hiera('profiles::mysql_config::innodb-flush-log-at-trx-commit'),
     'innodb-log-file-size'                       => hiera('profiles::mysql_config::innodb-log-file-size'),
     'innodb-log-files-in-group'                  => hiera('profiles::mysql_config::innodb-log-files-in-group'),
     'innodb-buffer-pool-size'                    => "${innodb_buffer_pool_size}",
     'innodb_file_format'                         => hiera('profiles::mysql_config::innodb_file_format'),
     'innodb_file_format_max'                         => hiera('profiles::mysql_config::innodb_file_format_max'),
     'innodb_flush_neighbors'                     => hiera('profiles::mysql_config::innodb_flush_neighbors'),
     'innodb_log_buffer_size'                     => hiera('profiles::mysql_config::innodb_log_buffer_size'),
     'innodb-buffer-pool-dump-at-shutdown'        => hiera('profiles::mysql_config::innodb-buffer-pool-dump-at-shutdown'),
     'innodb-buffer-pool-load-at-startup'         => hiera('profiles::mysql_config::innodb-buffer-pool-load-at-startup'),
     'innodb_buffer_pool_instances'               => "$innodb_buffer_pool_instances",
     'innodb-file-per-table'                      => hiera('profiles::mysql_config::innodb-file-per-table'),

    # LOGGING #
     'log_output'                                 => hiera('profiles::mysql_config::log_output'),
     'log_warnings'                               => hiera('profiles::mysql_config::log_warnings'),
     'log-error'                                  => hiera('profiles::mysql_config::log-error'),
     'log-queries-not-using-indexes'              => hiera('profiles::mysql_config::log-queries-not-using-indexes'),
     'log_slow_admin_statements'                  => hiera('profiles::mysql_config::log_slow_admin_statements'),
     'slow-query-log'                             => hiera('profiles::mysql_config::slow-query-log'),
     'slow-query-log-file'                        => hiera('profiles::mysql_config::slow-query-log-file'),
     'long_query_time'                            => hiera('profiles::mysql_config::long_query_time'),
     'general_log'                                => hiera('profiles::mysql_config::general_log'),
     'general_log_file'                           => hiera('profiles::mysql_config::general_log_file'),

    # PERFORMANCE_SCHEMA #
     'performance_schema'                         => hiera('profiles::mysql_config::performance_schema'),
     'performance_schema_consumer_statements_digest' => hiera('profiles::mysql_config::performance_schema_consumer_statements_digest'),
     'performance_schema_consumer_events_statements_history_long' => hiera('profiles::mysql_config::performance_schema_consumer_events_statements_history_long'),
          }
 }


}
