api :list_apps do |params,user|
  keys = App.redis.keys "app:*:name"
  res = []
  keys.each do |key|
    key = key.split(':')[1]
    app = App.with_key key if App.is_exist? key, 'name'
    res << { :name => app.name,
      :sources => app.sources.members,
      :users => app.users.members
    } if app
  end
  res.to_json
end