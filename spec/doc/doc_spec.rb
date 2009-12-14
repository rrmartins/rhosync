require File.join(File.dirname(__FILE__),'..','spec_helper')
require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'
require 'pp'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

require File.join(File.dirname(__FILE__),'..','..','rhosync.rb')

describe "Rhosync Protocol" do
  include Rack::Test::Methods
  include RhosyncStore
  
  Logger.enabled = false
  
  it_should_behave_like "SourceAdapterHelper"

  def app
    @app ||= Sinatra::Application
  end
  
  after(:each) do
    _print_messages
  end
  
  describe "unauthenticated routes - clientlogin" do
    it "end clientlogin" do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    end
  end
  
  describe "unauthenticated routes - clientlogin with wrong login or password " do
    it "end wrong login or password clientlogin" do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'wrongpass'
    end
  end
  
  describe "authenticated routes" do
    before(:each) do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    end
    
    describe "- clientcreate" do
      it "end clientcreate" do 
        get "/apps/#{@a.name}/clientcreate"
      end
    end
    
    describe "- clientregister" do
      it "end clientregister" do
        do_post "/apps/#{@a.name}/clientregister", "device_type" => "iPhone", "client_id" => @c.id
      end
    end
    
    describe "- clientreset" do
      it "end clientreset" do
        get "/apps/#{@a.name}/clientreset", :client_id => @c.id
      end
    end
    
    ['create','update','delete'].each do |operation|
      describe "- client #{operation} object(s)" do
        it "end client #{operation} object(s)" do
          params = {operation=>{'1'=>@product1},
                    :client_id => @c.id,
                    :source_name => @s.name}
          do_post "/apps/#{@a.name}", params
        end
      end
    end
    
    describe "- client create,update,delete objects" do
      it "end client create,update,delete objects" do
        params = {'create'=>{'1'=>@product1},
                  'update'=>{'2'=>@product2},
                  'delete'=>{'3'=>@product3},
                  :client_id => @c.id,
                  :source_name => @s.name}
        do_post "/apps/#{@a.name}", params
      end
    end
    
    describe "- client create object where backend provides object id in adapter.create" do
      it "end client create object where backend provides object id in adapter.create" do
        @product4['link'] = 'test link'
        params = {'create'=>{'4'=>@product4},
                  :client_id => @c.id,
                  :source_name => @s.name}
        do_post "/apps/#{@a.name}", params
        _print_messages
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,
          :version => ClientSync::VERSION
      end
    end
    
    describe "- server send source query error to client" do
      it "end server send source query error to client" do
        set_test_data('test_db_storage',{},"Error during query",'query error')
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      end
    end
    
    describe "- server send source login error to client" do
      it "end server send source login error to client" do
        @u.login = nil
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      end
    end
    
    describe "- server send source logoff error to client" do
      it "end server send source logoff error to client" do
        set_test_data('test_db_storage',{},"Error logging off",'logoff error')
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      end
    end
    
    ['create','update','delete'].each do |operation|
      describe "- client #{operation} object(s) with error" do
        it "end client #{operation} object(s) with error" do
          params = {operation=>{ERROR=>{'an_attribute'=>"error #{operation}",'name'=>'wrongname'}},
                    :client_id => @c.id,
                    :source_name => @s.name}
          do_post "/apps/#{@a.name}", params
          get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        end
      end
    end
    
    describe "- server send insert objects to client" do
      it "end server send insert objects to client" do
        cs = ClientSync.new(@s,@c,1)
        data = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',data)
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      end
    end
    
    describe "- server send delete objects to client" do
      it "end server send delete objects to client" do 
        cs = ClientSync.new(@s,@c,1)
        data = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',data)
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        token = @store.get_value(cs.clientdoc.get_page_token_dockey)
        @store.flash_data('test_db_storage')
        @s.refresh_time = Time.now.to_i
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
          :version => ClientSync::VERSION
      end
    end
    
    describe "- server send insert,delete objects to client" do
      it "end server send insert,delete objects to client" do 
        cs = ClientSync.new(@s,@c,1)
        data = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',data)
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        token = @store.get_value(cs.clientdoc.get_page_token_dockey)
        set_test_data('test_db_storage',{'1'=>@product1,'3'=>@product3})
        @s.refresh_time = Time.now.to_i
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
          :version => ClientSync::VERSION
      end
    end
    
    describe "- server send search results" do
      it "end server send search results" do
        sources = ['SampleAdapter']
        @store.put_data('test_db_storage',@data)
        params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
          :version => ClientSync::VERSION}
        get "/apps/#{@a.name}/search",params
      end
    end
    
    describe "- should get search results with error" do
      it "end should get search results with error" do
        sources = ['SampleAdapter']
        msg = "Error during search"
        error = set_test_data('test_db_storage',@data,msg,'search error')
        params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
          :version => ClientSync::VERSION}
        get "/apps/#{@a.name}/search",params
      end
    end
    
    describe "- should get multiple source search results" do
      it "end should get multiple source search results" do
        @s_fields[:name] = 'SimpleAdapter'
        @s1 = Source.create(@s_fields)
        @store.put_data('test_db_storage',@data)
        sources = ['SimpleAdapter','SampleAdapter']
        params = {:client_id => @c.id,:sources => sources,:search => {'search' => 'bar'},
          :version => ClientSync::VERSION}
        get "/apps/#{@a.name}/search",params
      end  
    end
  end
  
  private
  def _print_messages
    method = last_request.env['REQUEST_METHOD']
    query_string = last_request.env['QUERY_STRING'].empty? ? '' : "?#{last_request.env['QUERY_STRING']}"
    body = last_request.body.read
    response_body = last_response.body
    puts '-'*25 + 'REQUEST' + '-'*25
    puts "METHOD URL: #{method} #{last_request.env['PATH_INFO']}#{query_string}"
    puts '-'*57
    puts "Request Headers: "
    puts ' "Content-Type"=>' + last_request.env['CONTENT_TYPE'].inspect unless method == 'GET'
    puts ' "Content-Length"=>' + last_request.env['CONTENT_LENGTH'].inspect unless method == 'GET'
    puts ' "Cookie"=>' + last_request.env['HTTP_COOKIE'].inspect
    if not body.empty?
      puts "Request Body:"
      puts body
    end
    puts '-'*25 + 'RESPONSE' + '-'*24
    puts "Response Headers: "
    pp last_response.headers
    puts "Response Status: " + last_response.status.to_s
    if not response_body.empty?
      puts "Response body: "
      puts response_body
    end
  end
end