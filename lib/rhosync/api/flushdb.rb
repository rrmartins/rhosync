Rhosync::Server.api :flushdb do |params,user|
  if user.admin == 1
    Store.db.flushdb
    create_admin_user
  end
end