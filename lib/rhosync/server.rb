$:.unshift File.join(File.dirname(__FILE__),'..')
require 'sinatra/base'
require 'erb'
require 'json'
require 'fileutils'
require 'rhosync'

module Rhosync
  
  class ApiException < Exception
    attr_accessor :error_code
    def initialize(error_code,message)
      super(message)
      @error_code = error_code
    end  
  end
    
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
        login ? status(200) : status(401)
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
          session[:app_name] = APP_NAME
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
        if @user and (@user.admin == 1 || session[:app_name] == APP_NAME)
          @user
        else  
          nil
        end  
      end

      def api_user
        request_action == 'get_api_token' ? current_user : ApiToken.load(params[:api_token]).user
      end

      def current_app
        App.load(APP_NAME)
      end

      def current_source
        return @source if @source 
        user = current_user
        if params[:source_name] and user
          @source = Source.load(params[:source_name],
            {:user_id => user.login,:app_id => APP_NAME}) 
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
      
      def source_config
        { "sources" => Rhosync.get_config(Rhosync.base_directory)[:sources] }
      end

      def catch_all
        begin
          yield
        rescue Exception => e
          #log e.message + e.backtrace.join("\n")
          throw :halt, [500, e.message]
        end
      end
    end
        
    def initialize
      # Whine about default session secret
      check_default_secret!(Server.secret)
      super
    end
    
    Rhosync.log "Rhosync Server v#{Rhosync::VERSION} started..."

    before do
      if params["cud"]
        cud = JSON.parse(params["cud"])
        params.delete("cud")
        params.merge!(cud)
      end
      if request.env['CONTENT_TYPE'] == 'application/json'
        params.merge!(JSON.parse(request.body.read))
        request.body.rewind
      end      
      if params[:version] and params[:version].to_i < 3
        throw :halt, [404, "Server supports version 3 or higher of the protocol."]
      end
      #log "request params: #{params.inspect}"
    end

    %w[get post].each do |verb|
      send(verb, "/application*") do
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

    post '/application/clientlogin' do
      logout
      do_login
    end

    get '/application/clientcreate' do
      content_type :json
      client = Client.create(:user_id => current_user.id,:app_id => current_app.id)
      client.update_fields(params)
      { "client" => { "client_id" =>  client.id.to_s } }.merge!(source_config).to_json
    end

    post '/application/clientregister' do
      current_client.update_fields(params)
      source_config.to_json
    end

    get '/application/clientreset' do
      ClientSync.reset(current_client)
      source_config.to_json
    end

    # Member routes
    get '/application' do
      catch_all do
        content_type :json
        cs = ClientSync.new(current_source,current_client,params[:p_size])
        res = cs.send_cud(params[:token],params[:query]).to_json
        res
      end
    end

    post '/application' do
      catch_all do
        cs = ClientSync.new(current_source,current_client,params[:p_size]) 
        cs.receive_cud(params)
        status 200
      end
    end

    get '/application/bulk_data' do
      catch_all do
        content_type :json
        data = ClientSync.bulk_data(params[:partition].to_sym,current_client)
        data.to_json
      end
    end

    get '/application/search' do
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
          rescue ApiException => ae
            throw :halt, [ae.error_code, ae.message]  
          rescue Exception => e
            # log e.message + "\n" + e.backtrace.join("\n")
            throw :halt, [500, e.message]
          end
        else
          throw :halt, [422, "No API token provided"]
        end
      end
    end
  end
end

include Rhosync
Dir[File.join(File.dirname(__FILE__),'api','**','*.rb')].each { |api| load api }