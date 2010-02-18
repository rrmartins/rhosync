Rhosync::Server.api :create_user do |params,user|
  app = App.load(params[:app_name])
  if user.admin == 1 and app and params[:attributes]
    u = User.create({:login => params[:attributes]['login']})
    u.password = params[:attributes]['password']
    app.users << u.login
    "User created"
  end
end