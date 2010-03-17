#!/usr/bin/env ruby
require 'init'
require 'resque/server'
require 'rhosync/server'

Rhosync::Server.disable :run
Rhosync::Server.disable :clean_trace
Rhosync::Server.enable  :raise_errors
Rhosync::Server.set     :environment, Rhosync.environment
Rhosync::Server.set     :secret,      '<changeme>'
Rhosync::Server.set     :root,        File.dirname(__FILE__)

Rhosync::Server.use Rack::Static, :urls => ["/data"], :root => Rhosync.base_directory

# Setup the url map for rhosync and resque
# Note: If you don't want to expose the resque frontend, disable it here
run Rack::URLMap.new \
	"/" => Rhosync::Server.new,
	"/resque" => Resque::Server.new