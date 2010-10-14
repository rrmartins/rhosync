$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'sinatra/base'
require 'erb'
require 'json'
require 'rhosync_api'

module RhosyncConsole  
  class << self
    ROOT_DIR = File.dirname(File.expand_path(__FILE__)) unless defined? ROOT_DIR

    def root_path(*args)
      File.join(ROOT_DIR, *args)
    end
  end  

  class Server < Sinatra::Base
    set :views,  RhosyncConsole::root_path("app","views")
    set :public, RhosyncConsole::root_path("app","public")
    set :static, true    
    use Rack::Session::Cookie
  end
end

Dir[File.join(File.dirname(__FILE__),"app/**/*.rb")].each do |file|
  require file
end