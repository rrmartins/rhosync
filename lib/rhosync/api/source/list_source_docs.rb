Server.api :list_source_docs, :source do |params,user|
  res = {}
  s = Source.load(params[:source_id], {:app_id => APP_NAME,:user_id => params[:user_id]})
  [:md,:md_size,:md_copy,:errors].each do |doc|
    db_key = s.docname(doc)
    res.merge!(doc => db_key)
  end
  res.to_json
end

