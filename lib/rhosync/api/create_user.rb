Rhosync::Server.api :create_user do |params,user|
  app = App.load(params[:app_name])
  u = User.create({:login => params[:attributes]['login']})
  u.password = params[:attributes]['password']
  app.users << u.login
  "User created"
end