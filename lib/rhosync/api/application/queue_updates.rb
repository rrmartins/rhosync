Server.api :queue_updates, :application, :post do |params,user,server|
  server.catch_all do
    server.current_client_sync.receive_cud(params)
    server.status 200
  end
end