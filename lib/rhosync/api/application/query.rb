Server.api :query, :application, :get do |params,user,server|
  server.catch_all do
    server.content_type :json
    res = server.current_client_sync.send_cud(params[:token],params[:query]).to_json
    res
  end
end