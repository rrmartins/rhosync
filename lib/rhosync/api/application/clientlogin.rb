Server.app_api_post :clientlogin, :application do |server,params|
  server.catch_all do      
    server.logout
    server.do_login
  end  
end