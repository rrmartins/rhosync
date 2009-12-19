api :update_user do |app_name,user,payload|
  user = User.authenticate(payload[:login], payload[:password])
  raise RhosyncServerError.new("Unknown user/password") unless user
  user.update(payload[:attributes])
end