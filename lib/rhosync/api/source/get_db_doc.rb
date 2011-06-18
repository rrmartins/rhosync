Server.api :get_db_doc, :source do |params,user|
  if params[:data_type] and params[:data_type] == 'string'
    Store.get_value(params[:doc])
  else
    Store.get_data(params[:doc]).to_json
  end  
end