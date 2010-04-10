class RhosyncConsole::Server
  get '/' do
    unless login_required
      handle_api_error("Can't load list of application partition sources") do
        @sources = RhosyncApi::list_sources(session[:server],session[:app_name],session[:token],:app)
      end
    end
    erb :index
  end
end