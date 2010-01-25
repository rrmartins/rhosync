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
set :secret, 'secure!'

require File.join(File.dirname(__FILE__),'..','..','app.rb')

describe "Rhosync Protocol" do
  include Rack::Test::Methods
  include Rhosync
  
  Logger.enabled = false
  
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"

  def app
    @app ||= Sinatra::Application
  end
  
  before(:all) do
    $rand_id ||= 0
    $content_table ||= []
    $content ||= []
  end
  
  before(:each) do
    do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    @title,@description = nil,nil
    $rand_id += 1
  end
  
  after(:each) do
    #_print_messages
    _print_markdown if @title and @description
  end
  
  after(:all) do
    _write_doc if $content and $content.length > 0
  end
  
  it "clientlogin" do
    do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    @title,@description = 'clientlogin', 'authenticate client'
  end
  
  it "wrong login or password clientlogin" do
    do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'wrongpass'
    @title,@description = 'clientlogin', 'login failure'
  end
  
  it "clientcreate" do 
    get "/apps/#{@a.name}/clientcreate"
    @title,@description = 'clientcreate', 'create client id'          
  end
  
  it "clientregister" do
    do_post "/apps/#{@a.name}/clientregister", "device_type" => "iPhone", "client_id" => @c.id
    @title,@description = 'clientregister', 'register client device_type'     
  end
  
  it "clientreset" do
    get "/apps/#{@a.name}/clientreset", :client_id => @c.id
    @title,@description = 'clientreset', 'reset client database'
  end
  
  ['create','update','delete'].each do |operation|
    it "client #{operation} object(s)" do
      params = {operation=>{'1'=>@product1},
                :client_id => @c.id,
                :source_name => @s.name}
      do_post "/apps/#{@a.name}", params
      @title,@description = operation, "#{operation} object(s)"
    end
  end
  
  it "client create,update,delete objects" do
    params = {'create'=>{'1'=>@product1},
              'update'=>{'2'=>@product2},
              'delete'=>{'3'=>@product3},
              :client_id => @c.id,
              :source_name => @s.name}
    do_post "/apps/#{@a.name}", params
    @title,@description = 'create-update-delete', 'create,update,delete object(s)'
  end
  
  it "server sends link created object" do
    @product4['link'] = 'test link'
    params = {'create'=>{'4'=>@product4},
              :client_id => @c.id,
              :source_name => @s.name}
    do_post "/apps/#{@a.name}", params
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,
      :version => ClientSync::VERSION
    @title,@description = 'create-with-link', 'send link for created object'
  end
  
  it "server send source query error to client" do
    set_test_data('test_db_storage',{},"Error during query",'query error')
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
    @title,@description = 'query-error', 'send query error'
  end
  
  it "server send source login error to client" do
    @u.login = nil
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
    @title,@description = 'login-error', 'send login error'
  end
  
  it "server send source logoff error to client" do
    set_test_data('test_db_storage',{},"Error logging off",'logoff error')
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
    @title,@description = 'logoff-error', 'send logoff error'
  end
  
  ['create','update','delete'].each do |operation|
    it "client #{operation} object(s) with error" do
      params = {operation=>{ERROR=>{'an_attribute'=>"error #{operation}",'name'=>'wrongname'}},
                :client_id => @c.id,
                :source_name => @s.name}
      do_post "/apps/#{@a.name}", params
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      @title,@description = "#{operation}-error", "send #{operation} error"
    end
  end
  
  it "server send insert objects to client" do
    cs = ClientSync.new(@s,@c,1)
    data = {'1'=>@product1,'2'=>@product2}
    set_test_data('test_db_storage',data)
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
    @title,@description = 'insert objects', 'send insert objects'
  end
  
  it "server send delete objects to client" do 
    cs = ClientSync.new(@s,@c,1)
    data = {'1'=>@product1,'2'=>@product2}
    set_test_data('test_db_storage',data)
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
    token = Store.get_value(@c.docname(:page_token))
    Store.flash_data('test_db_storage')
    @s.get_read_state.refresh_time = Time.now.to_i
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
      :version => ClientSync::VERSION
    @title,@description = 'delete objects', 'send delete objects'
  end
  
  it "server send insert,delete objects to client" do 
    cs = ClientSync.new(@s,@c,1)
    data = {'1'=>@product1,'2'=>@product2}
    set_test_data('test_db_storage',data)
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
    token = Store.get_value(@c.docname(:page_token))
    set_test_data('test_db_storage',{'1'=>@product1,'3'=>@product3})
    @s.get_read_state.refresh_time = Time.now.to_i
    get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
      :version => ClientSync::VERSION
    @title,@description = 'insert-delete objects', 'send insert and delete objects'
  end
  
  it "server send search results" do
    sources = ['SampleAdapter']
    Store.put_data('test_db_storage',@data)
    params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
      :version => ClientSync::VERSION}
    get "/apps/#{@a.name}/search",params
    @title,@description = 'search result', 'send search results'
  end
  
  it "should get search results with error" do
    sources = ['SampleAdapter']
    msg = "Error during search"
    error = set_test_data('test_db_storage',@data,msg,'search error')
    params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
      :version => ClientSync::VERSION}
    get "/apps/#{@a.name}/search",params
    @title,@description = 'search error', 'send search error'
  end
  
  it "should get multiple source search results" do
    @s_fields[:name] = 'SimpleAdapter'
    @s1 = Source.create(@s_fields,@s_params)
    Store.put_data('test_db_storage',@data)
    sources = ['SimpleAdapter','SampleAdapter']
    params = {:client_id => @c.id,:sources => sources,:search => {'search' => 'bar'},
      :version => ClientSync::VERSION}
    get "/apps/#{@a.name}/search",params
    @title,@description = 'multi source search', 'send multiple sources in search results'
  end  
  
  private
  # def _print_messages
  #   method = last_request.env['REQUEST_METHOD']
  #   query_string = last_request.env['QUERY_STRING'].empty? ? '' : "?#{last_request.env['QUERY_STRING']}"
  #   body = last_request.body.read
  #   last_request.body.rewind
  #   response_body = last_response.body
  #   puts '-'*25 + 'REQUEST' + '-'*25
  #   puts "METHOD URL: #{method} #{last_request.env['PATH_INFO']}#{query_string}"
  #   puts '-'*57
  #   puts "Request Headers: "
  #   puts ' "Content-Type"=>' + last_request.env['CONTENT_TYPE'].inspect unless method == 'GET'
  #   puts ' "Content-Length"=>' + last_request.env['CONTENT_LENGTH'].inspect unless method == 'GET'
  #   puts ' "Cookie"=>' + last_request.env['HTTP_COOKIE'].inspect
  #   if not body.empty?
  #     puts "Request Body:"
  #     puts body
  #   end
  #   puts '-'*25 + 'RESPONSE' + '-'*24
  #   puts "Response Headers: "
  #   pp last_response.headers
  #   puts "Response Status: " + last_response.status.to_s
  #   if not response_body.empty?
  #     puts "Response body: "
  #     puts response_body
  #   end
  # end
  
  def _print_markdown
    $content_table << {$rand_id => "#{@title} - #{@description}"}
    data = {
      :title => @title,
      :description => @description,
      :rand_id => $rand_id,
      :req_method => last_request.env['REQUEST_METHOD'],
      :req_url => last_request.env['PATH_INFO'],
      :req_query_string => last_request.env['QUERY_STRING'].empty? ? '' : "?#{last_request.env['QUERY_STRING']}",
      :req_content_type => _get_header_text(last_request.env['CONTENT_TYPE']),
      :req_content_length => _get_header_text(last_request.env['CONTENT_LENGTH']),
      :req_cookie => _get_header_text(last_request.env['HTTP_COOKIE']),
      :req_body => last_request.body.read,
      :res_status => last_response.status.to_s,
      :res_content_type => _get_header_text(last_response.headers['Content-Type']),
      :res_content_length => _get_header_text(last_response.headers['Content-Length']),
      :res_cookie => _get_header_text(last_response.headers['Set-Cookie']),
      :res_body => last_response.body
    }
    last_request.body.rewind
    $content << data
  end
  
  def _write_doc
    File.open(File.join('doc','protocol.html'),'w') do |file|
      header = ERB.new(File.read(File.join(File.dirname(__FILE__),'header.html'))).result(binding)
      file.write(header)
      page = ERB.new(File.read(File.join(File.dirname(__FILE__),'base.html')))
      $content.each do |data|
        file.write(page.result(binding))
      end
      footer = ERB.new(File.read(File.join(File.dirname(__FILE__),'footer.html'))).result(binding)
      file.write(footer)
    end
  end
  
  def _get_header_text(header)
    header ? header : '&nbsp;'
  end
end