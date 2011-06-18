Server.app_api_get :clientcreate, :application do |server, params|
  server.catch_all do 
    server.content_type :json
    client = Client.create(:user_id => server.current_user.id,:app_id => server.current_app.id)
    client.update_fields(params)
    { "client" => { "client_id" =>  client.id.to_s } }.merge!(server.source_config).to_json
  end
end