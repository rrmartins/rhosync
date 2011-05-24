Server.api :push_objects do |params,user|
  source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
  # if source does not exist create one for dynamic adapter
  source = Source.create({:name => params[:source_id]},{:app_id => APP_NAME}) unless source
  source_sync = SourceSync.new(source)
  source_sync.push_objects(params[:objects])
  'done'
end