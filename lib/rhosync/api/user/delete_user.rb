Server.api :delete_user, :user do |params,user|
  User.load(params[:user_id]).delete
  App.load(APP_NAME).users.delete(params[:user_id])
  "User deleted"
end