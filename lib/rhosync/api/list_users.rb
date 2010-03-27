Rhosync::Server.api :list_users do |params,user|
  App.load(params[:app_name]).users.members.to_json
end