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
    
    # default secret
    @@secret = '<changeme>'
    
    # stats middleware disabled by default
    @@stats = false
                                                                                         
    # Setup route and mimetype for bulk data downloads
    # TODO: Figure out why "mime :data, 'application/octet-stream'" doesn't work
    Rack::Mime::MIME_TYPES['.data'] = 'application/octet-stream'   
     
    include Rhosync
                                                              
    helpers do
      def request_action
        request.env['PATH_INFO'].split('/').last
      end

      def check_api_token
        request_action == 'login' or request_action == 'get_api_token' or 
          (params[:api_token] and ApiToken.is_exist?(params[:api_token]))
      end

      def do_login
        begin
          login ? status(200) : status(401)
        rescue LoginException => le
          throw :halt, [401, le.message]
        rescue Exception => e
          throw :halt, [500, e.message]
        end
      end

      def login_required
        current_user.nil?
      end  

      def login
        if params[:login] == 'rhoadmin'
          user = User.authenticate(params[:login], params[:password])
        elsif current_app and current_app.can_authenticate?
          user = current_app.authenticate(params[:login], params[:password], session)
        end
        if user
          session[:login] = user.login
          session[:app_name] = APP_NAME
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
        if request_action == 'get_api_token'
          current_user
        else
          u = ApiToken.load(params[:api_token])
          raise "Wrong API token - #{params[:api_token].inspect}" unless u
          u.user 
        end
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
             
          # if source does not exist create one for dynamic adapter
          @source = Source.create({:name => params[:source_name]},{:app_id => APP_NAME}) unless @source
          
          #raise "ERROR: Source '#{params[:source_name]}' requested by client doesn't exist.\n" unless @source
          @source
        else
          log "ERROR: Can't load source, no source_name provided.\n"
          nil
        end
      end

      def current_client
        if @client.nil? and params[:client_id]
          @client = Client.load(params[:client_id].to_s,
            params[:source_name] ? {:source_name => current_source.name} : {:source_name => '*'})
          if @client and current_user and @client.user_id != current_user.login
            @client.switch_user(current_user.login) 
          end
          @client
        end  
      end
      
      def current_client_sync
        ClientSync.new(current_source,current_client,params[:p_size])
      end

      def catch_all
        begin
          yield
        rescue Exception => e
          log e.message + e.backtrace.join("\n")
          throw :halt, [500, e.message]
        end
      end
      
      def execute_api_call
        if check_api_token
          begin
            res = yield params,api_user
            if params.has_key? :warning
              Rhosync.log params[:warning]
              response.headers['Warning'] = params[:warning]
            end
            res
          rescue ApiException => ae
            throw :halt, [ae.error_code, ae.message]  
          rescue Exception => e
            log e.message + "\n" + e.backtrace.join("\n")
            throw :halt, [500, e.message]
          end
        else
          throw :halt, [422, "No API token provided"]
        end
      end
    end
    
    # hook into new so we can enable middleware
    def self.new
      if @@stats == true
        use Rhosync::Stats::Middleware 
        Rhosync.stats = true
      end
      use Rack::Session::Cookie, 
            :key => 'rhosync_session',
            :expire_after => 31536000,
            :secret => @@secret     
      super
    end
    
    def self.set(option, value=self, &block)
      @@stats = value if option == :stats and (value.is_a?(TrueClass) or value.is_a?(FalseClass))
      @@secret = value if option == :secret and value.is_a?(String)
      super
    end
        
    def initialize
      # Whine about default session secret
      check_default_secret!(@@secret)
      super
    end
    
    Rhosync.log "Rhosync Server v#{Rhosync::VERSION} started..."

    before do
      cache_control :no_cache
      headers({'pragma'=>'no-cache'})

      begin
        if params["cud"]
          cud = JSON.parse(params["cud"])
          params.delete("cud")
          params.merge!(cud)
        end
        #application/json; charset=UTF-8
        if request.env['CONTENT_TYPE'] && request.env['CONTENT_TYPE'].match(/^application\/json/)
          params.merge!(JSON.parse(request.body.read))
          request.body.rewind
        end      
      rescue JSON::ParserError => jpe
        log jpe.message + jpe.backtrace.join("\n")
        throw :halt, [500, "Server error while processing client data"]
      rescue Exception => e
        log e.message + e.backtrace.join("\n")
        throw :halt, [500, "Internal server error"]
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
      warning_message = "Use of the '/login' is deprecated. You should use '/api/admin/login' instead"
      response.headers['Warning'] = warning_message
      Rhosync.log warning_message
      call env.merge('PATH_INFO' => "/api/admin/login")
    end

    post '/application/clientlogin' do
      catch_all do      
        logout
        do_login
      end
    end

    get '/application/clientcreate' do
      catch_all do 
        content_type :json
        client = Client.create(:user_id => current_user.id,:app_id => current_app.id)
        client.update_fields(params)
        { "client" => { "client_id" =>  client.id.to_s } }.merge!(source_config).to_json
      end
    end

    post '/application/clientregister' do
      catch_all do 
        current_client.update_fields(params)
        source_config.to_json
      end
    end

    get '/application/clientreset' do
      catch_all do 
        ClientSync.reset(current_client)
        source_config.to_json
      end
    end

    # Member routes
    get '/application' do
      catch_all do
        content_type :json
        res = current_client_sync.send_cud(params[:token],params[:query]).to_json
        res
      end
    end

    post '/application' do
      catch_all do
        current_client_sync.receive_cud(params)
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

    def self.api(name, namespace = nil, &block)
      post "/api/#{name}" do
        namespace_val = namespace.nil? ? "<namespace>" : "#{namespace}"
        warning_message = "Use of the api/#{name} is deprecated. You should use api/#{namespace_val}/#{name} instead."
        response.headers['Warning'] = warning_message
        Rhosync.log warning_message
        if namespace != nil  
          call env.merge('PATH_INFO' => "/api/#{namespace}/#{name}")
        else
          execute_api_call &block
        end
      end
      
      if "#{name}" == 'login' 
        post "/api/#{namespace}/login" do
          begin
            yield params, self
          rescue ApiException => ae
            throw :halt, [ae.error_code, ae.message]  
          rescue Exception => e
            log e.message + "\n" + e.backtrace.join("\n")
            throw :halt, [500, e.message]
          end
        end
      else
        post "/api/#{namespace}/#{name}" do
          execute_api_call &block
        end
      end
    end
  end
end

include Rhosync
Dir[File.join(File.dirname(__FILE__),'api','**','*.rb')].each { |api| load api }