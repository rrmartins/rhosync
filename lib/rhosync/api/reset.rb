Rhosync::Server.api :reset do |params,user|
  if user.admin == 1
    Store.db.flushdb
    config = Rhosync.get_config(Rhosync.base_directory)
    app_klass = Object.const_get(camelize(Rhosync.get_app_name(config)))
    if app_klass.singleton_methods.include?("initializer")
      app_klass.send :initializer 
    else
      Rhosync.bootstrap(Rhosync.base_directory) 
    end  
  end
end