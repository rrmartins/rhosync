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
      throw :halt, [500, e.message]
    end
  end
end