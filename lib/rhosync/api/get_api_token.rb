api :get_api_token do |params,user|
  user.token.value if user and user.token
end