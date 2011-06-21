Server.api :update_user, :user do |params,user|
  user.update(params[:attributes])
  "User updated"
end