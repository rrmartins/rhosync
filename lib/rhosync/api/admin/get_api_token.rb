puts " calling the load method here "
Server.api :get_api_token do |params,user|
    puts " we are in get_api_token and " + self.inspect
    get_api_token(params, user)
end