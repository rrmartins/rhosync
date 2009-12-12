require 'zip/zip'

api :create_app do |app_name,payload|
  upload_file(app_name,payload) if payload[:upload_file]
end

def upload_file(app_name,payload)
  appdir = File.join(RhosyncStore.app_directory,app_name)
  FileUtils.rm_rf(appdir)
  FileUtils.mkdir_p(appdir)
  uploaded_file = File.join(appdir, payload[:upload_file][:filename])
  File.open(uploaded_file, 'wb') do |file|
    file.write(payload[:upload_file][:tempfile].read)
  end
  Zip::ZipFile.open(uploaded_file) do |zip_file|
    zip_file.each do |f|
      f_path = File.join(appdir,f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path)
    end
  end
  FileUtils.rm_f(uploaded_file)
end