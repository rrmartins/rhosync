#!/usr/bin/env ruby

path = File.join(File.dirname(__FILE__),'..','..','lib')
$:.unshift path

# Try to load vendor-ed rhosync, otherwise load the gem
begin
  require 'vendor/rhosync/lib/rhosync/server'
  require 'vendor/rhosync/lib/rhosync/console/server'
rescue LoadError
  require 'rhosync/server'
  require 'rhosync/console/server'
end

# By default, turn on the resque web console
require 'resque/server'

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

SESSION_SECRET = '<changeme>'

# Rhosync server flags
Rhosync::Server.disable :run
Rhosync::Server.disable :clean_trace
Rhosync::Server.enable  :raise_errors
Rhosync::Server.set     :environment, :development
Rhosync::Server.set     :root,        ROOT_PATH
Rhosync::Server.enable  :stats
Rhosync::Server.use     Rack::Static, :urls => ["/data"], :root => Rhosync::Server.root
Rhosync::Server.use     Rack::Session::Cookie, 
                          :key => 'rhosync_session',
                          :expire_after => 31536000,
                          :secret => SESSION_SECRET
                           
# Load our rhosync application
require 'application'

# Setup the url map
run Rack::URLMap.new \
	"/"         => Rhosync::Server.new,
	"/resque"   => Resque::Server.new, # If you don't want resque frontend, disable it here
	"/console"  => RhosyncConsole::Server.new # If you don't want rhosync frontend, disable it here