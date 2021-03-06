Server.api :reset, :admin do |params,user|
  Store.db.flushdb
  app_klass = Object.const_get(camelize(APP_NAME))
  if app_klass.singleton_methods.map(&:to_sym).include?(:initializer)
    app_klass.send :initializer, Rhosync.base_directory
  end
  # restoring previous token value after flushdb
  user.token = params[:api_token]
  "DB reset"
end