class RhosyncConsole::Server
  HEROKU_SSO_SALT = "xJWXFfrKvPdMxNlW"
  
  
  get "/heroku/resources/:id" do
    begin
      # heroku authentication
      halt 403 unless ENV['INSTANCE_ID'] == params[:id]
      pre_token = params[:id] + ':' + HEROKU_SSO_SALT + ':' + params[:timestamp]
      token = Digest::SHA1.hexdigest(pre_token).to_s
      halt 403 if token != params[:token]
      halt 403 if params[:timestamp].to_i < (Time.now - 2*60).to_i
      
      # rhoconnect authentication
      session[:login] = 'rhoadmin'
      session[:connect] = 'direct'     
      session[:token] = RhosyncApi::get_token(session[:server],session[:login],'')
    rescue Exception => e
      session[:token] = nil
      halt 403 
    end
    redirect url_path('/'), 303
  end
  
end