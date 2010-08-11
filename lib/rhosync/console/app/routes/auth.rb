class RhosyncConsole::Server
  post '/login' do
    begin
      session[:errors] = nil      
      session[:login] = params[:login]
      session[:connect] = params[:connect]    
      session[:server_url] = params[:server] 
      session[:server] = params[:connect] == 'direct' ? nil : params[:server]
      
      #verify_presence_of :server, "Server is not provaided."
      verify_presence_of :login, "Login is not provaided."
      
      unless session[:errors]         
        session[:token] = RhosyncApi::get_token(session[:server],params[:login],params[:password])
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
