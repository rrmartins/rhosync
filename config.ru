#require 'rubygems'
#require 'sinatra'

#set :run, false
#set :environment, :production

#require 'rhosync.rb'

#configure :development,:production do 
#  RhosyncStore.bootstrap(File.join('apps'))
#end

#FileUtils.mkdir_p 'log' unless File.exists?('log')
#log = File.new("log/sinatra.log", "a+")
#$stdout.reopen(log)
#$stderr.reopen(log)

#run Sinatra::Application

require 'rubygems'
require 'sinatra'

set :run, false
set :environment, :production
enable :raise_errors
set :clean_trace, false

require 'rhosync.rb'

configure :development,:production do 
  RhosyncStore.bootstrap(File.join('apps'))
end

# FileUtils.mkdir_p 'log' unless File.exists?('log')
# log = File.new("log/sinatra.log", "a+")
# $stdout.reopen(log)
# $stderr.reopen(log)

run Sinatra::Application
