Server.api :list_clients, :client do |params,user|
  User.load(params[:user_id]).clients.members.to_json
end