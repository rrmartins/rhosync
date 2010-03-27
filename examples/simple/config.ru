#!/usr/bin/env ruby

# Try to load vendored rhosync, otherwise load the gem
begin
  require 'vendor/rhosync/lib/rhosync'
  require 'vendor/rhosync/lib/rhosync/console/server'
rescue LoadError
  require 'rhosync'
  require 'rhosync/console/server'
end

require 'rhosync/console/server'

require 'simple'
require 'resque/server'

# Rhosync server flags
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
	"/resque" => Resque::Server.new,
	"/console" => RhosyncConsole::Server.new