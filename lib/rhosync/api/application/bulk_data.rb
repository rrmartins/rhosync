Server.api :bulk_data, :application, :get do |params,user,server|
  server.catch_all do
    server.content_type :json
    data = ClientSync.bulk_data(params[:partition].to_sym,server.current_client)
    data.to_json
  end
end