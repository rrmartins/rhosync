api :create_app do |app_name,user,payload|
  upload_file(app_name,payload) if payload[:upload_file]
  App.with_key(app_name).delete if App.is_exist?(app_name,'name')
  config = YAML.load File.read(File.join(RhosyncStore.app_directory,app_name,'config.yml'))
  if config and config['sources']
    app = App.create(:name => app_name)
    appdir = App.appdir(app_name)
    set_load_path(appdir,app_name)
    load underscore(app_name+'.rb') if File.exists?(File.join(appdir,app_name+'.rb'))
    config['sources'].each do |source_name,fields|
      fields[:name] = source_name
      fields[:user_id] = user.login
      fields[:app_id] = app.name 
      source = Source.create(fields)
      app.sources << source.name
      # load ruby file for source adapter to re-load class
      load underscore(source.name+'.rb')
    end
  end
end

def set_load_path(appdir,app_name)
  check_and_add(appdir)
  check_and_add(File.join(appdir,'sources'))
  Dir["#{appdir}/vendor/*"].each do |dir|
    check_and_add(File.join(dir,'lib'))
  end
end

def upload_file(app_name,payload)
  appdir = App.appdir(app_name)
  FileUtils.rm_rf(appdir)
  FileUtils.mkdir_p(appdir)
  unzip_file(appdir,payload)
end