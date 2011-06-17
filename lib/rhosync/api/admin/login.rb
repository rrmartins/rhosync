Server.api :login, :admin do |params,server|
    token = ''
    server.logout
    server.do_login
    token = do_get_api_token(params, server.current_user)
end
