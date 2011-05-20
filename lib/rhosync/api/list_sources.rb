Server.api :list_sources do |params,user|
  sources = App.load(APP_NAME).sources.members
  puts "sources: #{sources.inspect}"
  if params[:partition_type].nil? or params[:partition_type] == 'all'
    sources.to_json 
  else
    res = []
    sources.each do |name|
      s = Source.load(name,{:app_id => APP_NAME,:user_id => '*'})
      if s.partition_type and s.partition_type == params[:partition_type].to_sym
        res << name 
      end
    end  
    res.to_json
  end  
end
