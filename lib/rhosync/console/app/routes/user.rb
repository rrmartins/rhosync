class RhosyncConsole::Server
  get '/users' do
    begin
      @users = RhosyncApi::list_users(
        session[:server],session[:app_name],session[:token]) 
    rescue Exception => e
      session[:errors] = ["Can't load list of users: [#{e.http_code}] #{e.message}"]
    end
    erb :users
  end
  
  get '/user/new' do
    erb :newuser
  end
  
  post '/user/create' do
    session[:errors] = nil
    verify_presence_of :login, "Login is not provaided."
    unless session[:errors]             
      begin  
        RhosyncApi::create_user(session[:server],
          session[:app_name],session[:token],params[:login],params[:password])
      rescue Exception => e
        session[:errors] = ["Can't create new user: [#{e.http_code}] #{e.message}"]
      end      
    end
    redirect url(session[:errors] ? '/user/new' : '/users'), 303  
  end
  
  get '/user' do
    erb :user
  end
  
  get '/user/delete' do
    begin 
      RhosyncApi::delete_user(session[:server],session[:app_name],session[:token],params[:user])
    rescue Exception => e
      session[:errors] = ["Can't delete user #{params[:user]}: [#{e.http_code}] #{e.message}"]
    end    
    redirect url(session[:errors] ? "/user?user=#{CGI.escape(params[:user])}" : '/users'), 303
  end
end