Server.api :create_client, :client do |params,user|
  Client.create(:user_id => params[:user_id],:app_id => APP_NAME).id
end