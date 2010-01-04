api :create_user do |params,user|
  app = App.with_key(params[:app_name])
  if user.admin == 1 and app and params[:attributes]
    u = User.create({:login => params[:attributes]['login']})
    u.password = params[:attributes]['password']
    app.users << u.login
  end
end