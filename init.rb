require 'yaml'
$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rhosync'
include Rhosync

Rhosync.bootstrap do |rhosync|
  rhosync.base_directory = File.dirname(__FILE__)
  rhosync.blackberry_bulk_sync = true # enable blackberry bulk sync? defaults to false
  rhosync.environment = (ENV['RHO_ENV'] || :development).to_sym
  
  # Enable this to setup the redis connection, format: <host>:<port>:<db>:<password>
  config = YAML.load_file('config.yml')[rhosync.environment]
  rhosync.redis = config[:redis]
end