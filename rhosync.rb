$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'fileutils'

require 'rhosync_store'
require 'helpers/rhosync_helper'

enable :raise_errors

include RhosyncStore

use Rack::Session::Cookie, :key => 'rhosync_session',
                           :path => '/',
                           :expire_after => 31536000,
                           :secret => '<changeme>'

configure :test do 
  add_adapter_path(File.join(File.dirname(__FILE__),'spec','adapters'))
end

configure :development,:test,:production do 
  RhosyncStore.bootstrap(File.join('apps'))
end

before do
  if request.env['CONTENT_TYPE'] == 'application/json'
    params.merge!(JSON.parse(request.body.read))
    request.body.rewind
  end
  if params[:version] and params[:version].to_i < 3
    throw :halt, [404, "Server supports version 3 or higher of the protocol."]
  end
end

%w[get post].each do |verb|
  send(verb, "/apps/:app_name*") do
    unless request.env['PATH_INFO'].split('/').last == 'clientlogin'
      throw :halt, [401, "Not authenticated"] if login_required
    end
    pass
  end
end

get "/" do
  erb :index
end

# Collection routes
post '/login' do
  logout
  do_login
end

post '/apps/:app_name/clientlogin' do
  logout
  do_login
end

get '/apps/:app_name/clientcreate' do
  client = Client.create(:user_id => current_user.id,:app_id => current_app.id)
  { "client" => { "client_id" =>  client.id.to_s } }.to_json
end

post '/apps/:app_name/clientregister' do
  current_client.device_type = params[:device_type]
  status 200
end

get '/apps/:app_name/clientreset' do
  ClientSync.reset(current_app,current_user,current_client)
  status 200
end

# Member routes
get '/apps/:app_name' do
  content_type :json
  cs = ClientSync.new(current_source,current_client,params[:p_size])
  cs.send_cud(params[:token],params[:query]).to_json
end

post '/apps/:app_name' do
  cs = ClientSync.new(current_source,current_client,params[:p_size]) 
  cs.receive_cud(params)
  status 200
end

get '/apps/:app_name/search' do
  content_type :json
  ClientSync.search_all(current_client,params[:sources],params[:search]).to_json
end

# Management routes
def api(name)
  post "/api/:app_name/#{name}" do
    yield params[:app_name],current_user,params[:payload]
  end
end

Dir["#{File.dirname(__FILE__)}/lib/rhosync_store/api/**/*.rb"].each { |api| load api }
