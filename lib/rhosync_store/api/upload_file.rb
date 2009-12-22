api :upload_file do |params,user|
  appdir = App.appdir(params[:app_name])
  unzip_file(appdir,params[:upload_file]) if File.exists?(appdir)
end