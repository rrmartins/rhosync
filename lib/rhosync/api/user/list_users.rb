Server.api :list_users, :user do |params,user|
  App.load(APP_NAME).users.members.to_json
end
