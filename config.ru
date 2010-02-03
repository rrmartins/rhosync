#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'lib')
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
  rhosync.blackberry_bulk_sync = true # defaults to false
end

Rhosync::Server.use Rack::Static, :urls => ["/data"], :root => Rhosync.base_directory

# Setup route and mimetype for bulk data downloads
#mime :data, 'application/octet-stream'

Rhosync::Server.use Rack::Session::Cookie, :key => 'rhosync_session',
  :expire_after => 31536000,
  :secret => Rhosync::Server.secret

# FileUtils.mkdir_p 'log' unless File.exists?('log')
# log = File.new("log/sinatra.log", "a+")
# $stdout.reopen(log)
# $stderr.reopen(log)

run Rack::URLMap.new \
	"/" => Rhosync::Server.new,
	"/resque" => Resque::Server.new