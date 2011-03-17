class RhosyncConsole::Server
  def render_page(contenturl)
    @currentpage = "Console"
    @initialcontent = contenturl
     @pagetitle = "Rhosync Console" #H1 title
     @locals = {
       :div => "main_box",
       :links => [ 
         { :url => url_path('/homepage'), :title => 'Info' },
         { :url => url_path('/doc/select'), :title => 'Server Document' },
         { :url => url_path('/users'), :selected => true, :title => 'Users' }
       ]
     }
     erb :content
  end
  
  get '/users' do
    if params[:xhr] or request.xhr?
      @users = []
      handle_api_error("Can't load list of users") do
        @users = RhosyncApi::list_users(session[:server],session[:token])
      end
      erb :users, :layout => false
      
    else
       render_page url_path("/users")
     end 
  end
  
  get '/user/new' do
    if params[:xhr] or request.xhr?
      erb :newuser, :layout => false
    else
      render_page url_path("/user/new")
    end 
      
  end
  
  post '/user/create' do
    session[:errors] = nil
    verify_presence_of :login, "Login is not provided."
    unless session[:errors]             
      handle_api_error("Can't create new user") do  
        RhosyncApi::create_user(session[:server],
          session[:token],params[:login],params[:password])
      end      
    end
    redirect url_path(session[:errors] ? '/user/new' : '/users'), 303  
  end
  
  get '/user' do
    if params[:xhr] or request.xhr?
    
      @devices = []
      handle_api_error("Can't load list of devices") do
        @devices = RhosyncApi::list_clients(
          session[:server],session[:token],params[:user_id])
      end
      @sources = []
      handle_api_error("Can't load list of user partition sources") do
        @sources = RhosyncApi::list_sources(session[:server],session[:token],:user)
      end
      erb :user, :layout => false
    else
       params[:user_id] = CGI::escape(params[:user_id]) if params[:user_id]
       render_page url_path("/user?user_id=#{params[:user_id]}")
    end     
  end
  
  get '/user/delete' do
    handle_api_error("Can't delete user #{params[:user_id]}") do 
      RhosyncApi::delete_user(session[:server],session[:token],params[:user_id])
    end    
    redirect url_path(session[:errors] ? "/user?user_id=#{CGI.escape(params[:user_id])}" : '/users'), 303
  end
  
  get '/user/ping' do
    if params[:xhr] or request.xhr?
    
      @sources = []
      handle_api_error("Can't load list of user partition sources") do
        @sources = RhosyncApi::list_sources(session[:server],session[:token],:all)
      end
      erb :ping, :layout => false
    else
      render_page url_path("/user/ping?user_id=#{CGI.escape(params[:user_id])}")
    end
    
  end
  
  post '/user/ping' do
    params['sources'] = params['sources'].split(',')
    handle_api_error("Error while pinging") do
      RhosyncApi::ping(session[:server],session[:token],params[:user_id],params)
    end
    user = CGI.escape(params[:user_id])
    redirect url_path(session[:errors] ? "/user/ping?user_id=#{user}" : "/user?user_id=#{user}"), 303
  end
end