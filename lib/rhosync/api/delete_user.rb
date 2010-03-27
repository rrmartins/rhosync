Rhosync::Server.api :delete_user do |params,user|
  User.load(params[:user]).delete
  App.load(params[:app_name]).users.delete(params[:user])
  "User deleted"
end