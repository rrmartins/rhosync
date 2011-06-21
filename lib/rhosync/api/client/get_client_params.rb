Server.api :get_client_params, :client do |params,user|
  Client.load(params[:client_id],{:source_name => '*'}).to_array.to_json
end
