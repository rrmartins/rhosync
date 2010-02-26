#gem 'sevenwire-rest-client'
require 'rest_client'
require 'log4r'
require 'json'
$:.unshift File.dirname(__FILE__)
require 'trunner/timer'
require 'trunner/logging'
require 'trunner/result'
require 'trunner/session'
require 'trunner/runner'
require 'trunner/statistics'
require 'trunner/cli'

# Inspired by Trample: http://github.com/jamesgolick/trample

module Trunner
  class << self
    include Logging

    attr_accessor :concurrency, :iterations, :login, :password, :host, :base_url
    
    def config
      yield self
    end
    
    def set_server_state(doc,data)
      res = RestClient.post("#{@host}/login", 
        {:login => @login, :password => @password}.to_json, :content_type => :json)
      puts "cookies: #{res.cookies.inspect}"
      headers = 
      token = RestClient.post("#{@host}/api/get_api_token",'',{:cookies => res.cookies})
      RestClient.post("#{@host}/api/set_db_doc",
        {:api_token => token, :doc => doc, :data => data}.to_json, :content_type => :json)
    end
  
    def test(&block)
      Runner.new.test(@concurrency,@iterations,&block)
    end
  end
end