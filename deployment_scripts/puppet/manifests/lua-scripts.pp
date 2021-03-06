
notice('MODULAR: fuel-plugin-telemetry: lua-scripts.pp')

$modules_dir = hiera('telemetry::lua::modules_dir')

$dirs = [
  $modules_dir,
  "${modules_dir}/common",
  "${modules_dir}/decoders",
  "${modules_dir}/encoders",
  "${modules_dir}/filters",
  '/usr/share/heka',
  '/usr/share/heka/lua_modules'
]

file { $dirs:
  ensure  => 'directory',
  recurse => true,
}

# Common script for heka and hindsight

$scripts = {
  "${modules_dir}/common/ceilometer.lua" => {
    source => 'puppet:///modules/telemetry/common/ceilometer.lua'
  },
  "${modules_dir}/common/samples.lua" => {
    source => 'puppet:///modules/telemetry/common/samples.lua'
  },
  "${modules_dir}/decoders/metering.lua" => {
    source => 'puppet:///modules/telemetry/decoders/metering.lua'
  },
  "${modules_dir}//common/resources.lua" => {
    source => 'puppet:///modules/telemetry//common/resources.lua'
  },
}


create_resources(file, $scripts)

# Scripts imported from lma_collector module
# see pre_build_hook

$lma_scripts = {
  "${modules_dir}/common/lma_utils.lua" => {
    source => 'puppet:///modules/telemetry/import/common/lma_utils.lua'
  },
  "${modules_dir}/common/patterns.lua" => {
    source => 'puppet:///modules/telemetry/import/common/patterns.lua'
  },
  "${modules_dir}/common/influxdb.lua" => {
    source => 'puppet:///modules/telemetry/import/common/influxdb.lua'
  },
  "${modules_dir}/common/accumulator.lua" => {
    source => 'puppet:///modules/telemetry/import/common/accumulator.lua'
  },
  "${modules_dir}/filters/influxdb_accumulator.lua" => {
    source => 'puppet:///modules/telemetry/import/filters/influxdb_accumulator.lua'
  },
  "${modules_dir}/encoders/es_ceilometer_resources.lua" => {
    source => 'puppet:///modules/telemetry/import/encoders/es_ceilometer_resources.lua'
  },
  "${modules_dir}/common/extra_fields.lua" => {
    source => 'puppet:///modules/telemetry/common/extra_fields.lua'
  },
  "${modules_dir}/common/elasticsearch_resources.lua" => {
    source => 'puppet:///modules/telemetry/common/elasticsearch_resources.lua'
  }
}

create_resources(file, $lma_scripts)
