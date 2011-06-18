Server.app_api_post :queue_updates, :application do |server, params|
  server.catch_all do
    server.current_client_sync.receive_cud(params)
    server.status 200
  end
end