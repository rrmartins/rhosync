Server.api :login, :admin do |params,server|
    token = ''
    begin 
      server.logout
      server.do_login
      token = do_get_api_token(params, server.current_user)
    rescue ApiException => e
      token = ''
    end
    token
end
