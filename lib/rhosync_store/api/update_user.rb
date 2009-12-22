api :update_user do |params,user|
  user = User.authenticate(params[:login], params[:password])
  raise RhosyncServerError.new("Unknown user/password") unless user
  user.update(params[:attributes])
end