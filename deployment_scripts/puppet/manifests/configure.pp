notice('MODULAR: fuel-plugin-telemetry: configure.pp')

# Let's use already defined params for ceilometer
include ::ceilometer::params

# TODO_0 'set' default values when looking for via hiera
# TODO_1 add if statments in case of 'advanced settings' passed through Fuel UI
# TODO_2 checks if we can reach ES, influxdb before actioning?
# Still needed $aodh_nodes ?
$aodh_nodes              = hiera('aodh_nodes')

# TODO_3 es_node should be configured because of a bug in Ceilometer API
if hiera('lma::collector::elasticsearch::server', false) {
  $elasticsearch_node      = hiera('lma::collector::elasticsearch::server')
  $elasticsearch_port      = hiera('lma::collector::elasticsearch::rest_port')
} else {
  $elasticsearch_node      = '0.0.0.0'
  $elasticsearch_port      = '9200'
}

$ceilometer_service_name = $::ceilometer::params::api_service_name
# TODO move to hiera
$event_pipeline_file     = '/etc/ceilometer/event_pipeline.yaml'
# TODO move to hiera
$ceilometer_publishers   = 'direct'

$influxdb_address  = hiera('telemetry::influxdb::address')
$influxdb_port     = hiera('telemetry::influxdb::port')
$influxdb_database = hiera('telemetry::influxdb::database')
$influx_user       = hiera('telemetry::influxdb::user')
$influx_password   = hiera('telemetry::influxdb::password')

$metering_connection = "stacklight://${influx_user}:${influx_password}@${influxdb_address}:${influxdb_port}/${influxdb_database}"

$resource_connection = "es://${elasticsearch_node}:${elasticsearch_port}"
$event_connection    = "es://${elasticsearch_node}:${elasticsearch_port}"
$connection          = $metering_connection

$packages = {
  'ceilometer-collector' => {
    # keep 'absent' instead of 'purged' for idempotence
    ensure => 'absent',
    require => Service['ceilometer-collector'],
  },
  'python-pip' => {
    ensure => 'present',
  },
  'influxdb' => {
    ensure => 'present',
    provider => 'pip',
    require => Package['python-pip'],
    # Not sure at a momment
    notify => Service['ceilometer-service']
  },
  'elasticsearch' => {
    ensure => 'present',
    provider => 'pip',
    require => Package['python-pip'],
    # Not sure at a momment
    notify => Service['ceilometer-service']
  },
}

# TODO FOR V3: stop collector only when qeue is empty*
# *wait utill all the events went from collector
#  before stop collector service
# maybe service'collector' ensure stopped; require exec 'wait for qeue is empty'

create_resources(package, $packages)

# Stop not needed any more service
service { 'ceilometer-collector':
    ensure    => stopped,
    enable    => false,
    hasstatus => true,
}

# TODO validate values before proceed

ceilometer_config { 'database/metering_connection': value => $metering_connection }
ceilometer_config { 'database/resource_connection': value => $resource_connection }
ceilometer_config { 'database/event_connection':    value => $event_connection }
ceilometer_config { 'database/connection':          value => $connection }
ceilometer_config { 'notification/store_events':    value => false }


service { 'ceilometer-service':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::api_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      tag        => 'ceilometer-service',
    }

Ceilometer_config<||> ~> Service['ceilometer-service']

class { 'telemetry':
  event_pipeline_file => $event_pipeline_file,
  publishers          => $ceilometer_publishers,
}
