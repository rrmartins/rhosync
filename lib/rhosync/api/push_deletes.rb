Server.api :push_deletes do |params,user|
  source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
  source_sync = SourceSync.new(source)
  source_sync.push_deletes(params[:objects])
  'done'
end
