Rhosync::Server.api :create_client do |params,user|
  Client.create(:user_id => params[:user_id],:app_id => params[:app_name]).id
end