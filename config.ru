require 'rubygems'
require 'sinatra'
require 'resque/server'

disable :run, :clean_trace
set :environment, :production
enable :raise_errors
set :secret, '<changeme>'

require 'rhosync.rb'

configure :development,:production do 
  RhosyncStore.bootstrap do |rhosync|
	rhosync.app_directory = File.join('apps')
	rhosync.data_directory = File.join('data')
	rhosync.blackberry_bulk_sync = true # defaults to false
  end
end

# FileUtils.mkdir_p 'log' unless File.exists?('log')
# log = File.new("log/sinatra.log", "a+")
# $stdout.reopen(log)
# $stderr.reopen(log)

run Rack::URLMap.new \
	"/" => Sinatra::Application,
	"/resque" => Resque::Server.new

