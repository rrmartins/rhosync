Server.api :clientreset, :application, :get do |params,user,server|
  server.catch_all do 
    ClientSync.reset(server.current_client)
    server.source_config.to_json
  end
end