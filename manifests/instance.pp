# == Defined type swagger::instance
#
# Full description of defined type swagger::instance here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { swagger:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <william.leese@meltwater.com>
#
define swagger::instance (
  $version = '2.0.12',
  $download = true,
  $download_url = undef,
  $download_extract_dir = '/opt',
  $tomcat_webapp_dir = '/var/lib/tomcat/webapps',
  $doc_title = 'Swagger UI',
  $resource_listing_url = 'http://petstore.swagger.wordnik.com/api/api-docs',
  $logo_url = 'http://swagger.wordnik.com',
  $user = 'root',
  $group = 'root',
) {

  $download_root_dir = "swagger-ui-${version}"

  if $download {
    if $download_url {
      $download_url_real = $download_url
    } else {
      $download_url_real = "https://codeload.github.com/wordnik/swagger-ui/zip/v${version}"
    }

    $ext = regsubst($download_url_real, '.*\.(.*$)', '\1', 'G')

    unless $ext == 'zip' or $ext == 'zip' or $ext == 'tar.gz' or $ext == 'tar.bz2' or $ext == 'tgz' or $ext == 'tgz2' {
      $extension_real = 'zip'
    }

    archive { $name:
      url            => $download_url_real,
      target         => $download_extract_dir,
      root_dir       => $download_root_dir,
      checksum       => false,
      extension      => $extension_real,
      allow_insecure => true,
      timeout        => 1600,
    }

    exec { "${name} copy to webapps dir":
      command => "cp -a ${download_extract_dir}/${download_root_dir}/dist ${tomcat_webapp_dir}/swagger",
      creates => "${tomcat_webapp_dir}/swagger",
      require => Archive[$name]
    }
    ->
    exec { "${name} chown swagger dir":
      command     => "chown -R ${user}:${group} ${tomcat_webapp_dir}/swagger",
      refreshonly => true,
    }

    file { 'swagger-index':
      ensure  => present,
      path    => "${tomcat_webapp_dir}/swagger/index.html",
      source  => "${download_extract_dir}/${download_root_dir}/dist/index.html",
      owner   => $user,
      group   => $group,
      require => Exec["${name} chown swagger dir"],
    }

  }
}
