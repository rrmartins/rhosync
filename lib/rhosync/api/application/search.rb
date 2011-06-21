Server.api :search, :application, :get do |params,user,server|
  server.catch_all do
    server.content_type :json
    ClientSync.search_all(server.current_client,params).to_json
  end
end  