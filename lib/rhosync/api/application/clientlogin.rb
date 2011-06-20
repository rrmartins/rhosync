Server.api :clientlogin, :application, :post do |params,user,server|
  server.catch_all do      
    server.logout
    server.do_login
  end  
end