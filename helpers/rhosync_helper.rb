helpers do
  def login_required
    current_user.nil?
  end
  
  def login
    if current_app.can_authenticate?
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
    puts "appname: #{@appname}"
    if User.is_exist?(session[:login],'login') && session[:app_name] == params[:app_name]
      User.with_key(session[:login])
    end
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