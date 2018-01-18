class role::mysql() {
    include ::profile::mysql
    include ::profile::mysql::monitoring
    include ::profile::mysql::audit
    include ::profile::mysql::auth
}
