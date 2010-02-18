Rhosync::Server.api :delete_app do |params,user|
  App.load(params[:app_name]).delete if App.is_exist?(params[:app_name])
  FileUtils.rm_rf File.join(File.dirname(__FILE__),'..','..','..','apps',params[:app_name])
  "App deleted"
end