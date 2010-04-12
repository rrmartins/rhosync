Rhosync::Server.api :list_users do |params,user|
  App.load(APP_NAME).users.members.to_json
end
