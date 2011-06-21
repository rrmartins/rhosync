Server.api :clientregister, :application, :post do |params,user,server|
  server.catch_all do 
    server.current_client.update_fields(params)
    server.source_config.to_json
  end
end