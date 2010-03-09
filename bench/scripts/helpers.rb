module TrunnerHelpers
  def client_docname(app_id,user_id,client_id,source_name,doctype)
    "client:#{app_id}:#{user_id}:#{client_id}:#{source_name}:#{doctype}"
  end
  
  def source_docname(app_id,user_id,source_name,doctype)
    "source:#{app_id}:#{user_id}:#{source_name}:#{doctype}"
  end
end