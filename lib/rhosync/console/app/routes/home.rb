class RhosyncConsole::Server
  get '/' do
    @currentpage = "Console" #which page in menu
    if login_required
      @pagetitle = "Login" #H1 title
      @initialcontent = url('/loginpage')

      @locals = {
        :div => "main_box",
        :links => [ 
        #  { :url => url('/timing/bydevice'), :selected => true, :title => 'By Device' },
        #  { :url => url('/timing/bysource'), :title => 'By Source' }
        ]
      }
    else
      @pagetitle = "Application" #H1 title
      @initialcontent = url('/homepage')

      @locals = {
        :div => "main_box",
        :links => [ 
          { :url => url('/homepage'), :selected => true, :title => 'License' },
          { :url => url('/doc/select'), :title => 'Server Document' },
          { :url => url('/users'), :title => 'Users' }
        ]
      }
    end
    erb :content
  end
  
  get '/loginpage' do
    erb :login, :layout => :false
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
    redirect url('/'), 303
  end
end