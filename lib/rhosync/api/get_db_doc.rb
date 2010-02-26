Rhosync::Server.api :get_db_doc do |params,user|
  Store.get_data(params['doc']).to_json
end