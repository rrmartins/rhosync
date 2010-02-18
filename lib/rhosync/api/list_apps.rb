Rhosync::Server.api :list_apps do |params,user|
  keys = App.redis.keys "app:*:name"
  res = []
  keys.each do |key|
    key = key.split(':')[1]
    app = App.load key if App.is_exist?(key)
    res << { :name => app.name,
      :sources => app.sources.members,
      :users => app.users.members
    } if app
  end
  res.to_json
end