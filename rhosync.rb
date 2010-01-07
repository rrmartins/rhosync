$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'fileutils'

require 'rhosync_store'
require 'helpers/rhosync_helper'

enable :raise_errors
set :secret, '<changeme>' unless defined? Sinatra::Application.secret

include RhosyncStore

use Rack::Session::Cookie, :key => 'rhosync_session',
                           :path => '/',
                           :expire_after => 31536000,
                           :secret => Sinatra::Application.secret

# Whine about the default session secret
check_default_secret!

Logger.info "Rhosync Server v#{RhosyncStore::VERSION} started..."

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
    unless request_action == 'clientlogin'
      throw :halt, [401, "Not authenticated"] if login_required
    end
    pass
  end
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
  content_type :json
  client = Client.create(:user_id => current_user.id,:app_id => current_app.id)
  { "client" => { "client_id" =>  client.id.to_s } }.to_json
end

post '/apps/:app_name/clientregister' do
  current_client.device_type = params[:device_type]
  status 200
end

get '/apps/:app_name/clientreset' do
  ClientSync.reset(current_client)
  status 200
end

# Member routes
get '/apps/:app_name' do
  content_type :json
  cs = ClientSync.new(current_source,current_client,params[:p_size])
  res = cs.send_cud(params[:token],params[:query]).to_json
  puts "send_cud results: #{res.inspect}"
  res
end

post '/apps/:app_name' do
  puts "receive_cud params: #{params.inspect}"
  cs = ClientSync.new(current_source,current_client,params[:p_size]) 
  cs.receive_cud(params)
  status 200
end

get '/apps/:app_name/search' do
  content_type :json
  ClientSync.search_all(current_client,params).to_json
end

# Management routes
def api(name)
  post "/api/#{name}" do
    if check_api_token
      begin
        yield params,api_user
      rescue Exception => e
        throw :halt, [500, e.message]
      end
    else
      throw :halt, [422, "No API token provided"]
    end
  end
end

Dir["#{File.dirname(__FILE__)}/lib/rhosync_store/api/**/*.rb"].each { |api| load api }
