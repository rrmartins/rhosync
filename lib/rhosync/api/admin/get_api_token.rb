Server.api :get_api_token do |params,user|
    puts " we are in get_api_token and " + self.inspect
    do_get_api_token(params, user)
end

def do_get_api_token(params, user)
  puts " calloing do_get_api_token" + params.inspect + " user " + user.inspect
  if user and user.admin == 1 and user.token
    user.token.value 
  else
    raise ApiException.new(422, "Invalid/missing API user")
  end
end