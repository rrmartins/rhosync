Server.app_api_get :search, :application do |server, params|
  server.catch_all do
    server.content_type :json
    ClientSync.search_all(server.current_client,params).to_json
  end
end  