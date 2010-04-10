Rhosync::Server.api :list_source_docs do |params,user|
  res = {}
  s = Source.load(params[:source_id], {:app_id => params[:app_name],:user_id => params[:user_id]})
  [:md,:md_size,:md_copy,:errors].each do |doc|
    db_key = s.docname(doc)
    res.merge!(doc => db_key)
  end
  res.to_json
end

