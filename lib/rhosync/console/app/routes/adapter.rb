class RhosyncConsole::Server
  
  get '/adapter' do
    if params[:xhr] or request.xhr?
      @adapter = nil
      handle_api_error("Can't load adapter url") do
        @adapter = RhosyncApi::get_adapter(session[:server],session[:token])['adapter_url']
      end
      erb :adapter, :layout => false 
    else
       render_page url_path("/adapter")
     end
  end
  
  post '/adapter/create' do
    session[:errors] = nil
    verify_format_of :adapter_url, "url must start with http(s)"
    puts "errors: #{session[:errors]}"
    unless session[:errors]             
      handle_api_error("Can't save adapter url") do  
        RhosyncApi::save_adapter(session[:server],
          session[:token],params[:adapter_url])
      end      
    end
    redirect url_path( '/adapter'), 303
  end
  
end