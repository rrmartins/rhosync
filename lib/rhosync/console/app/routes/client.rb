class RhosyncConsole::Server
  
  get '/device/create' do
    session[:errors] = nil
    handle_api_error("Can't create new device") do  
      RhosyncApi::create_client(session[:server],
        session[:app_name],session[:token],params[:user_id])
    end      
    redirect url("/user?user_id=#{CGI.escape(params[:user_id])}"), 303  
  end
  
  get '/device' do
    @attributes = []
    handle_api_error("Can't load list of device attributes") do
      @attributes = RhosyncApi::get_client_params(session[:server],session[:app_name],session[:token],params[:device_id])
    end
    @sources = []
    handle_api_error("Can't load list of sources") do
      @sources = RhosyncApi::list_sources(session[:server],session[:app_name],session[:token],:all)
    end
    erb :client
  end
  
  get '/device/delete' do
    handle_api_error("Can't delete device #{params[:device_id]}") do 
      RhosyncApi::delete_client(session[:server],session[:app_name],session[:token],
        params[:user_id],params[:device_id])
    end    
    redirect url(session[:errors] ? "/device?user_id=#{CGI.escape(params[:user_id])}&device_id=#{CGI.escape(params[:device_id])}" :
      "/user?user_id=#{CGI.escape(params[:user_id])}"), 303
  end
end