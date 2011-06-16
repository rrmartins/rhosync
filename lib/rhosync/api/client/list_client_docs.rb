Server.api :list_client_docs do |params,user|
  c = Client.load(params[:client_id],{:source_name => params[:source_id]})
  res = {}
  [:cd,:cd_size,:create,:update,:delete,
   :page,:delete_page,:create_links,:create_links_page,:page_token,
   :create_errors,:update_errors,:delete_errors,:login_error,:logoff_error,
   :search,:search_token,:search_errors].each do |doc|
    db_key = c.docname(doc)
    res.merge!(doc => db_key)
  end
  res.to_json
end
