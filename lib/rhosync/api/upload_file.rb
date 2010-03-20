Rhosync::Server.api :upload_file do |params,user|
  unzip_file(Rhosync.app_directory,params[:upload_file]) if File.exists?(Rhosync.app_directory)
  "File uploaded"
end