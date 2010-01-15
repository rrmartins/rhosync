api :import_app do |params,user|
  app_name = params[:app_name]
  upload_file(app_name,params[:upload_file]) if params[:upload_file]
  App.load(app_name).delete if App.is_exist?(app_name)
  config = YAML.load File.read(File.join(RhosyncStore.app_directory,app_name,'config.yml'))
  if config and config['sources']
    app = App.create(:name => app_name)
    appdir = App.appdir(app_name)
    set_load_path(appdir)
    load underscore(app_name+'.rb') if File.exists?(File.join(appdir,app_name+'.rb'))
    config['sources'].each do |source_name,fields|
      fields[:name] = source_name
      source = Source.create(fields,{:user_id => user.login, :app_id => app.name})
      app.sources << source.name
      # load ruby file for source adapter to re-load class
      load underscore(source.name+'.rb')
    end
  end
  ''
end

def upload_file(app_name,params)
  appdir = App.appdir(app_name)
  FileUtils.rm_rf(appdir)
  FileUtils.mkdir_p(appdir)
  unzip_file(appdir,params)
end