api :delete_app do |app_name,user,payload|
  App.with_key(app_name).delete if App.is_exist?(app_name,'name')
  FileUtils.rm_rf File.join(File.dirname(__FILE__),'..','..','..','apps',app_name)
end