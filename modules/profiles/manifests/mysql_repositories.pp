class profiles::mysql_repositories {

apt::source { 'mariadb':
  comment  => 'This is MariaDB rep',
  location => 'http://mirror.i3d.net/pub/mariadb/repo/10.1/debian',
  repos    => 'main',
  key      => {
    'id'     => '199369E5404BD5FC7D2FE43BCBCB082A1BB943DB',
    'server' => 'keyserver.ubuntu.com',
  }
}

apt::source { 'percona':
  comment  => 'This is Percona rep',
  location => 'http://repo.percona.com/apt',
  repos    => 'main',
  key      => {
    'id'     => '430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A',
    'server' => 'keys.gnupg.net',
  }
}


}
