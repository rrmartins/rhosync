Server.api :login do |params,user|
    puts " we are here in login " + params['instance'].inspect
    
    logout
    do_login
    do_get_api_token(params, user)
end
