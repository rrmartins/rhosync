class RhosyncConsole::Server
  get '/' do
    unless login_required
      @license = nil
      handle_api_error("Can't get license information") do
        @license = RhosyncApi::get_license_info(session[:server],session[:token])
      end
      @sources = nil
      handle_api_error("Can't load list of application partition sources") do
        @sources = RhosyncApi::list_sources(session[:server],session[:app_name],session[:token],:app)
      end
    end
    erb :index
  end
  
  get '/reset' do
    handle_api_error("Can't reset server") do
      RhosyncApi::reset(session[:server],session[:token])
    end
    redirect url('/'), 303
  end
end