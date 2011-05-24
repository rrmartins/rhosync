class RhosyncConsole::Server
  get '/' do
    if params[:xhr] or request.xhr?
      if login_required
        redirect url_path('/loginpage')
      else
        redirect url_path('/homepage')
      end
    else
      @currentpage = "Console" #which page in menu
      if login_required
        @pagetitle = "Login" #H1 title
        @initialcontent = url_path('/loginpage')

        @locals = {
          :div => "main_box",
          :links => [ 
          #  { :url => url_path('/timing/bydevice'), :selected => true, :title => 'By Device' },
          #  { :url => url_path('/timing/bysource'), :title => 'By Source' }
          ]
        }
      else
        @pagetitle = "Rhosync Console" #H1 title
        @initialcontent = url_path('/homepage')

        @locals = {
          :div => "main_box",
          :links => [ 
            { :url => url_path('/homepage'), :selected => true, :title => 'Info' },
            { :url => url_path('/doc/select'), :title => 'Server Document' },
            { :url => url_path('/adapter'), :title => 'Adapter URL' },
            { :url => url_path('/users'), :title => 'Users' }
          ]
        }
      end
      erb :content
    end
  end
  
  get '/loginpage' do
    erb :login, :layout => false
  end
  
  get '/homepage' do
    @license = nil
    handle_api_error("Can't get license information") do
      @license = RhosyncApi::get_license_info(session[:server],session[:token])
    end
    @sources = nil
    handle_api_error("Can't load list of application partition sources") do
      @sources = RhosyncApi::list_sources(session[:server],session[:token],:app)
    end
    erb :home, :layout => false
  end
  
  get '/reset' do
    handle_api_error("Can't reset server") do
      RhosyncApi::reset(session[:server],session[:token])
    end
    redirect url_path('/'), 303
  end
end