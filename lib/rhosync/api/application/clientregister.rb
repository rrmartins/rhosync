Server.app_api_post :clientregister, :application do |server, params|
  server.catch_all do 
    server.current_client.update_fields(params)
    server.source_config.to_json
  end
end