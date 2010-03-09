#gem 'sevenwire-rest-client'
require 'rest_client'
require 'log4r'
require 'json'
$:.unshift File.dirname(__FILE__)
require 'trunner/timer'
require 'trunner/logging'
require 'trunner/utils'
require 'trunner/result'
require 'trunner/session'
require 'trunner/runner'
require 'trunner/statistics'
require 'trunner/cli'
require 'trunner/test_data'
$:.unshift File.join(File.dirname(__FILE__),'..')
require 'scripts/helpers'

# Inspired by Trample: http://github.com/jamesgolick/trample

module Trunner
  class << self
    include Logging
    include TestData
    include Utils

    attr_accessor :concurrency, :iterations, :admin_login 
    attr_accessor :admin_password, :user_name, :app_name
    attr_accessor :password, :host, :base_url, :token
    attr_accessor :total_time, :sessions, :verify_error
    
    def config
      begin
        @verify_error ||= false
        yield self
      rescue Exception => e
        puts "error in config: #{e.inspect}"
        raise e
      end
    end
    
    def get_server_state(doc)
      token = get_token
      @body = RestClient.post("#{@host}/api/get_db_doc",
        {:api_token => token, :doc => doc}.to_json, :content_type => :json)
      JSON.parse(@body)
    end
    
    def set_server_state(doc,data)
      token = get_token
      RestClient.post("#{@host}/api/set_db_doc",
        {:api_token => token, :doc => doc, :data => data}.to_json, :content_type => :json)
    end
    
    def reset_refresh_time(source_name,poll_interval=nil)
      token = get_token
      RestClient.post("#{@host}/api/set_refresh_time",
        {:api_token => token, :source_name => source_name,
          :app_name => @app_name, :user_name => @user_name, 
          :poll_interval => poll_interval}.to_json, 
          :content_type => :json)
    end
    
    def get_token
      unless @token
        res = RestClient.post("#{@host}/login", 
          {:login => @admin_login, :password => @admin_password}.to_json, :content_type => :json)
        @token = RestClient.post("#{@host}/api/get_api_token",'',{:cookies => res.cookies})
      end
      @token
    end
  
    def test(&block)
      Runner.new.test(@concurrency,@iterations,&block)
    end
    
    def verify(&block)
      yield self,@sessions
    end
  end
end