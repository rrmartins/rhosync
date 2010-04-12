Rhosync::Server.api :get_source_params do |params,user|
  Source.load(params[:source_id],{:app_id => APP_NAME,:user_id => '*'}).to_array.to_json
end
