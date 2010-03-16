#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'yaml'
require 'resque/server'
require 'rhosync/server'

Rhosync::Server.disable :run
Rhosync::Server.disable :clean_trace
Rhosync::Server.enable  :raise_errors
Rhosync::Server.set     :environment, :production
Rhosync::Server.set     :secret,      '<changeme>'
Rhosync::Server.set     :root,        File.dirname(__FILE__)

Rhosync.bootstrap do |rhosync|
  rhosync.base_directory = File.dirname(__FILE__)
  rhosync.blackberry_bulk_sync = true # enable blackberry bulk sync? defaults to false
  
  # Enable this to setup the redis connection, format: <host>:<port>:<db>:<password>
  config = YAML.load_file('config.yml')
  rhosync.redis = config['redis'][Server.environment.to_s]
end

Rhosync::Server.use Rack::Static, :urls => ["/data"], :root => Rhosync.base_directory

# Setup the url map for rhosync and resque
# Note: If you don't want to expose the resque frontend, disable it here
run Rack::URLMap.new \
	"/" => Rhosync::Server.new,
	"/resque" => Resque::Server.new