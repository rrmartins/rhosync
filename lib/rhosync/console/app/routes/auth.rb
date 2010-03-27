class RhosyncConsole::Server
  post '/login' do
    begin
      session[:server] = params[:server]
      session[:app_name] = params[:app_name]
      session[:login] = params[:login]
      session[:errors] = nil      
      
      verify_presence_of :server, "Server is not provaided."
      verify_presence_of :app_name, "Application name is not provaided."
      verify_presence_of :login, "Login is not provaided."
      
      unless session[:errors]         
        session[:token] = RhosyncApi::get_token(params[:server],params[:login],params[:password])
      end  
    rescue Exception => e
      session[:token] = nil
      report_error("Can't login to Rhosync server.")      
      #puts e.message + "\n" + e.backtrace.join("\n")
    end 
    redirect url('/'), 303
  end
  
  get '/logout' do
    session[:token] = nil
    redirect url('/'), 303
  end
  
end
