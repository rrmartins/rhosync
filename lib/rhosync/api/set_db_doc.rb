Rhosync::Server.api :set_db_doc do |params,user|
  Store.put_data(params['doc'],params['data'])
  ''
end