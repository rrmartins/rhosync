class RhosyncConsole::Server
  
  get "/heroku/resources/:id" do
    begin
      # check heroku addon started app
      halt 403 unless ENV['INSTANCE_ID'] == params[:id]
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