Server.api :delete_user do |params,user|
  User.load(params[:user_id]).delete
  App.load(APP_NAME).users.delete(params[:user_id])
  params = {:app_id => APP_NAME,:user_id => params[:user_id]}
  App.load(APP_NAME).sources.members.each{ |source|
    Source.load(source, params).flash_store_data
  }
  "User deleted"
end