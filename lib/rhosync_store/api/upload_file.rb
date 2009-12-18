api :upload_file do |app_name,user,payload|
  appdir = App.appdir(app_name)
  unzip_file(appdir,payload) if File.exists?(appdir)
end