# hiera_mssql::install
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include hiera_mssql::install
class hiera_mssql::install {
  if $::osfamily == 'RedHat' {
    $freetds_packages = ['freetds', 'freetds-devel']
  }

  package { $freetds_packages:
    ensure => present,
  }

  package { 'tiny_tds':
    ensure          => '0.7.0',
    provider        => puppet_gem,
    install_options => ['--', '--enable-system-freetds'],
    require         => Package[$freetds_packages],
  }

  package { 'jdbc-sqlserver':
    ensure   => present,
    provider => puppetserver_gem,
    notify   => Service['pe-puppetserver'],
  }

}
