Server.app_api_get :clientreset, :application do |server, params|
  server.catch_all do 
    ClientSync.reset(server.current_client)
    server.source_config.to_json
  end
end