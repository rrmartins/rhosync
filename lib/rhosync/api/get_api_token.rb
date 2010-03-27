Rhosync::Server.api :get_api_token do |params,user|
  if user and user.admin == 1 and user.token
    user.token.value 
  else
    raise ApiException.new(422, "Invalid/missing API user")
  end    
end