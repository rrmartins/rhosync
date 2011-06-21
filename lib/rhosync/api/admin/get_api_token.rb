Server.api :get_api_token, :admin do |params,user|
    warning_message = "API method 'get_api_token' is deprecated.
      Use 'login' method only, it returns api token in response's body"
    params[:warning] = warning_message unless params.nil?
    do_get_api_token(params, user)
end

def do_get_api_token(params, user)
  if user and user.admin == 1 and user.token
    user.token.value 
  else
    raise ApiException.new(422, "Invalid/missing API user")
  end
end