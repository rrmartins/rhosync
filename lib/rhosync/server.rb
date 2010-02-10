$:.unshift File.join(File.dirname(__FILE__),'..')
require 'sinatra/base'
require 'erb'
require 'json'
require 'fileutils'
require 'rhosync'

module Rhosync
  class Server < Sinatra::Base
    libdir = File.dirname(File.expand_path(__FILE__))
    set :views,  "#{libdir}/server/views"
    set :public, "#{libdir}/server/public"
    set :static, true
    
    set :secret, '<changeme>' unless defined? Server.secret
    
    use Rack::Session::Cookie, :key => 'rhosync_session',
                               :expire_after => 31536000,
                               :secret => Server.secret
                               
    # Setup route and mimetype for bulk data downloads
    # TODO: Figure out why "mime :data, 'application/octet-stream'" doesn't work
    Rack::Mime::MIME_TYPES['.data'] = 'application/octet-stream'   
     
    include Rhosync
                                                              
    helpers do
      def request_action
        request.env['PATH_INFO'].split('/').last
      end

      def check_api_token
        request_action == 'get_api_token' or 
          (params[:api_token] and ApiToken.is_exist?(params[:api_token]))
      end

      def do_login
        if login
          status 200
        else
          status 401
        end
      end

      def login_required
        current_user.nil?
      end

      def login
        if current_app and current_app.can_authenticate?
          user = current_app.authenticate(params[:login], params[:password], session)
        else
          user = User.authenticate(params[:login], params[:password])
        end
        if user
          session[:login] = user.login
          session[:app_name] = params[:app_name]
          true
        else
          false
        end
      end

      def logout
        session[:login] = nil
      end

      def current_user
        if @user.nil? and User.is_exist?(session[:login]) 
          @user = User.load(session[:login])
        end
        if @user and (@user.admin == 1 || session[:app_name] == params[:app_name])
          @user
        else  
          nil
        end  
      end

      def api_user
        request_action == 'get_api_token' ? current_user : ApiToken.load(params[:api_token]).user
      end

      def current_app
        App.load(params[:app_name]) if params[:app_name]
      end

      def current_source
        return @source if @source 
        user = current_user
        if params[:source_name] and params[:app_name] and user
          @source = Source.load(params[:source_name],
            {:user_id => user.login,:app_id => params[:app_name]}) 
        else
          nil
        end
      end

      def current_client
        if @client.nil? and params[:client_id]
          @client = Client.load(params[:client_id].to_s,
            params[:source_name] ? {:source_name => current_source.name} : {:source_name => '*'}) 
        end  
      end

      def catch_all
        begin
          yield
        rescue Exception => e
          #puts e.message + e.backtrace.join("\n")
          throw :halt, [500, e.message]
        end
      end
    end
    
    Logger.info "Rhosync Server v#{Rhosync::VERSION} started..."
    
    def initialize
      # Whine about default session secret
      check_default_secret!(Server.secret)
      super
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
        unless request_action == 'clientlogin'
          throw :halt, [401, "Not authenticated"] if login_required
        end
        pass
      end
    end

    get '/' do
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
      catch_all do
        content_type :json
        cs = ClientSync.new(current_source,current_client,params[:p_size])
        res = cs.send_cud(params[:token],params[:query]).to_json
        #puts "send_cud results: #{res.inspect}"
        res
      end
    end

    post '/apps/:app_name' do
      catch_all do
        #puts "receive_cud params: #{params.inspect}"
        cs = ClientSync.new(current_source,current_client,params[:p_size]) 
        cs.receive_cud(params)
        status 200
      end
    end

    get '/apps/:app_name/bulk_data' do
      catch_all do
        content_type :json
        data = ClientSync.bulk_data(params[:partition].to_sym,current_client)
        data.to_json
      end
    end

    get '/apps/:app_name/search' do
      catch_all do
        content_type :json
        ClientSync.search_all(current_client,params).to_json
      end
    end

    def self.api(name)
      post "/api/#{name}" do
        if check_api_token
          begin
            yield params,api_user
          rescue Exception => e
            #puts e.message + e.backtrace.join("\n")
            throw :halt, [500, e.message]
          end
        else
          throw :halt, [422, "No API token provided"]
        end
      end
    end
  end
end

Dir[File.join(File.dirname(__FILE__),'api','**','*.rb')].each { |api| load api }