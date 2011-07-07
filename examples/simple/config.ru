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

require 'x_domain_session_wrapper'
use XDomainSessionWrapper

# By default, turn on the resque web console
require 'resque/server'

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

# Rhosync server flags
Rhosync::Server.disable :run
Rhosync::Server.disable :clean_trace
Rhosync::Server.enable  :raise_errors
Rhosync::Server.set     :root,        ROOT_PATH
Rhosync::Server.enable  :stats
Rhosync::Server.set     :secret, '<changeme>'
Rhosync::Server.use     Rack::Static, :urls => ["/data"], :root => Rhosync::Server.root
                     
# configure Cross-Domain Resource Sharing
require 'cors'
use Rack::Cors do |cfg|
  cfg.allow do |allow|
    allow.origins /.*/
#        /http:\/\/192\.168\.0\.\d{1,3}(:\d+)?/,
#        /http:\/\/localhost(:\d+)?/, /http:\/\/127\.0\.0\.\d{1,3}(:\d+)?/,
#        /file:\/\//, /null/, /.*/
    allow.resource '/application',   :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
    allow.resource '/application/*', :headers => :any, :methods => [:get, :post, :put, :delete], :credentials => true
  end
end                     
                           
# Load our rhosync application
require 'application'

# Setup the url map
run Rack::URLMap.new \
	"/"         => Rhosync::Server.new,
	"/resque"   => Resque::Server.new, # If you don't want resque frontend, disable it here
	"/console"  => RhosyncConsole::Server.new # If you don't want rhosync frontend, disable it here