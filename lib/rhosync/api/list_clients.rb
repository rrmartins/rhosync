Rhosync::Server.api :list_clients do |params,user|
  User.load(params[:user_id]).clients.members.to_json
end