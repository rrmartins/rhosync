Server.app_api_get :query, :application do |server, params|
  server.catch_all do
    server.content_type :json
    res = server.current_client_sync.send_cud(params[:token],params[:query]).to_json
    res
  end
end