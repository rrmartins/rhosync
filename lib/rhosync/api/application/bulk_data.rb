Server.app_api_get :bulk_data, :application do |server, params|
  server.catch_all do
    server.content_type :json
    data = ClientSync.bulk_data(params[:partition].to_sym,server.current_client)
    data.to_json
  end
end