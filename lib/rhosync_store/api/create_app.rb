require 'zip/zip'

api :create_app do |app_name,user,payload|
  upload_file(app_name,payload) if payload[:upload_file]
  App.with_key(app_name).delete if App.is_exist?(app_name,'name')
  config = YAML.load File.read(File.join(RhosyncStore.app_directory,app_name,'config.yml'))
  if config and config['sources']
    app = App.create(:name => app_name)
    config['sources'].each do |source_name,fields|
      fields[:name] = source_name
      fields[:user_id] = user.login
      fields[:app_id] = app.name 
      source = Source.create(fields)
      app.sources << source.name
    end
  end
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