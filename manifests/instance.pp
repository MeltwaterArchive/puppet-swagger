# == Defined type swagger::instance
#
# Installs swagger-ui (https://github.com/wordnik/swagger-ui/)
#
# === Parameters
#
# [*version*]
#   Which version of swagger-ui to install.
#
# [*download*]
#   true or false to decide whether swagger is installed by download or package.
#   We currently only support download based install. Default is true
#
# [*download_url*]
#   Where to download swagger-ui from. Note that this url if specified, must either
#   end with a archive extension (.gz, .gzip, .zip) or else '.zip' will be assumed.
#   If this does not match up, then the module will fail to install swagger-ui,
#
# [*download_extract_dir*]
#   Where to extract swagger-ui to. This is just a temporary storage until the app
#   is copied into $tomcat_webapp_dir.
#
# [*tomcat_webapp_dir*]
#   Where to copy swagger-ui to.
#
# [*doc_title*]
#   The title of the swagger-ui index page.
#
# [*resource_listing_url*]
#   api-docs URL.
#
# [*logo_url*]
#   Where to link the logo to.
#
# [*user*]
#   The user the swagger-ui app is chowned to.
#
# [*group*]
#   The group the swagger-ui app is chowned to.
#
# === Examples
#
#  class { swagger:
#    version           => '2.0.12',
#    tomcat_webapp_dir => '/opt/tomcat-6.0.29/webapps',
#  }
#
# === Authors
#
# Author Name <william.leese@meltwater.com>
#
define swagger::instance (
  $version = undef,
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

  if $version {
    $version_real = $version
  } else {
    $version_real = '2.0.12'
  }
  $version_maj = regsubst($version_real, '^([0-9]*)\..*', '\1')

  $download_root_dir = "swagger-ui-${version_real}"

  if $download {
    if $download_url {
      $download_url_real = $download_url
    } else {
      $download_url_real = "https://codeload.github.com/wordnik/swagger-ui/zip/v${version_real}"
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
      require => Archive[$name],
    }
    ->
    exec { "${name} chown swagger dir":
      command     => "chown -R ${user}:${group} ${tomcat_webapp_dir}/swagger",
      refreshonly => true,
    }

    file { 'swagger-index':
      ensure  => present,
      path    => "${tomcat_webapp_dir}/swagger/index.html",
      content => template("swagger/index.html-${version_maj}.erb"),
      owner   => $user,
      group   => $group,
      require => Exec["${name} chown swagger dir"],
    }

  }
}
