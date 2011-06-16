Server.api :set_db_doc do |params,user|
  if params[:data_type] and params[:data_type] == 'string'
    Store.put_value(params[:doc],params[:data])
  else
    Store.put_data(params[:doc],params[:data])
  end  
  ''
end