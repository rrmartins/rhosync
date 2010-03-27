require 'rest_client'

module RhosyncApi
  class << self
    
    def get_token(server,login,password)
      res = RestClient.post("#{server}/login", 
          {:login => login, :password => password}.to_json, :content_type => :json)
      RestClient.post("#{server}/api/get_api_token",'',{:cookies => res.cookies})
    end
    
    def list_users(server,app_name,token)
      JSON.parse(RestClient.post("#{server}/api/list_users",
        {:app_name => app_name, :api_token => token}.to_json, :content_type => :json))
    end
    
    def create_user(server,app_name,token,login,password)
      RestClient.post("#{server}/api/create_user",
        {:app_name => app_name, :api_token => token,
         :attributes => {:login => login, :password => password}}.to_json, 
         :content_type => :json)
    end  
    
    def delete_user(server,app_name,token,user)
      RestClient.post("#{server}/api/delete_user",
        {:app_name => app_name, :api_token => token, :user => user}.to_json, 
         :content_type => :json)    
    end
      
  end
end