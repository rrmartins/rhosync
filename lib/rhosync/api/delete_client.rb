Rhosync::Server.api :delete_client do |params,user|
  Client.load(params[:client_id],{:source_name => '*'}).delete
  User.load(params[:user_id]).clients.delete(params[:client_id])
  "Client deleted"
end