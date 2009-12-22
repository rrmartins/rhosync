helpers do
  def request_action
    request.env['PATH_INFO'].split('/').last
  end
  
  def check_api_token
    request_action == 'get_api_token' or 
      (params[:api_token] and ApiToken.is_exist?(params[:api_token],'value'))
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
    if User.is_exist?(session[:login],'login') 
      user = User.with_key(session[:login])
      return user if user.admin == 1 || session[:app_name] == params[:app_name]
    end
    nil
  end
  
  def api_user
    request_action == 'get_api_token' ? current_user : ApiToken.with_key(params[:api_token]).user
  end
  
  def current_app
    App.with_key(params[:app_name]) if params[:app_name]
  end
  
  def current_source
    Source.with_key(params[:source_name]) if params[:source_name]
  end
  
  def current_client
    Client.with_key(params[:client_id]) if params[:client_id]
  end
end