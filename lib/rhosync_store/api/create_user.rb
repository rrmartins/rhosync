api :create_user do |params,user|
  app = App.with_key(params[:app_name])
  if user.admin == 1 and app
    u = User.create({:login => params[:login]})
    u.password = params[:password]
    app.users << u.login
    u
  end
end