Rhosync::Server.api :update_user do |params,user|
  user.update(params[:attributes])
  "User updated"
end