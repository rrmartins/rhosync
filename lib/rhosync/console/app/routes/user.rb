class RhosyncConsole::Server
  get '/users' do
    @users = []
    handle_api_error("Can't load list of users") do
      @users = RhosyncApi::list_users(
        session[:server],session[:app_name],session[:token])
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
      handle_api_error("Can't create new user") do  
        RhosyncApi::create_user(session[:server],
          session[:app_name],session[:token],params[:login],params[:password])
      end      
    end
    redirect url(session[:errors] ? '/user/new' : '/users'), 303  
  end
  
  get '/user' do
    @clients = []
    handle_api_error("Can't load list of clients") do
      @clients = RhosyncApi::list_clients(
        session[:server],session[:app_name],session[:token],params[:user_id])
    end
    erb :user
  end
  
  get '/user/delete' do
    handle_api_error("Can't delete user #{params[:user_id]}") do 
      RhosyncApi::delete_user(session[:server],session[:app_name],session[:token],params[:user_id])
    end    
    redirect url(session[:errors] ? "/user?user_id=#{CGI.escape(params[:user_id])}" : '/users'), 303
  end
end