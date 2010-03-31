class RhosyncConsole::Server
  
  get '/client/create' do
    session[:errors] = nil
    handle_api_error("Can't create new client") do  
      RhosyncApi::create_client(session[:server],
        session[:app_name],session[:token],params[:user_id])
    end      
    redirect url("/user?user_id=#{CGI.escape(params[:user_id])}"), 303  
  end
  
  get '/client' do
    erb :client
  end
  
  get '/client/delete' do
    handle_api_error("Can't delete client #{params[:client_id]}") do 
      RhosyncApi::delete_client(session[:server],session[:app_name],session[:token],
        params[:user_id],params[:client_id])
    end    
    redirect url(session[:errors] ? "/client?user_id=#{CGI.escape(params[:user_id])}&client_id=#{CGI.escape(params[:client_id])}" :
      "/user?user_id=#{CGI.escape(params[:user_id])}"), 303
  end
end