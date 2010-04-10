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
        {:app_name => app_name, :api_token => token}.to_json, :content_type => :json).body)
    end
    
    def create_user(server,app_name,token,login,password)
      RestClient.post("#{server}/api/create_user",
        {:app_name => app_name, :api_token => token,
         :attributes => {:login => login, :password => password}}.to_json, 
         :content_type => :json)
    end  
    
    def delete_user(server,app_name,token,user_id)
      RestClient.post("#{server}/api/delete_user",
        {:app_name => app_name, :api_token => token, :user_id => user_id}.to_json, 
         :content_type => :json)    
    end
  
    def list_clients(server,app_name,token,user_id)
      JSON.parse(RestClient.post("#{server}/api/list_clients", {:app_name => app_name, 
        :api_token => token, :user_id => user_id}.to_json, :content_type => :json).body)
    end
    
    def create_client(server,app_name,token,user_id)
      RestClient.post("#{server}/api/create_client",
        {:app_name => app_name, :api_token => token, :user_id => user_id}.to_json, 
         :content_type => :json).body
    end  
    
    def delete_client(server,app_name,token,user_id,client_id)
      RestClient.post("#{server}/api/delete_client",
        {:app_name => app_name, :api_token => token, :user_id => user_id, 
         :client_id => client_id}.to_json, :content_type => :json)    
    end
    
    def list_sources(server,app_name,token,partition='all') 
      JSON.parse(RestClient.post("#{server}/api/list_sources", {:app_name => app_name, 
        :api_token => token, :partition_type => partition}.to_json, :content_type => :json).body)
    end

    def get_source_params(server,app_name,token,source_id)
      JSON.parse(RestClient.post("#{server}/api/get_source_params", {:app_name => app_name, 
        :api_token => token, :source_id => source_id}.to_json, :content_type => :json).body)
    end
    
    def list_source_docs(server,app_name,token,source_id,user_id='*')
      JSON.parse(RestClient.post("#{server}/api/list_source_docs", {:app_name => app_name, 
        :api_token => token, :source_id => source_id, :user_id => user_id}.to_json, :content_type => :json).body)
    end  
      
    def list_client_docs(server,app_name,token,source_id,client_id)
      JSON.parse(RestClient.post("#{server}/api/list_client_docs", {:app_name => app_name, 
        :api_token => token, :source_id => source_id, :client_id => client_id}.to_json, :content_type => :json).body)
    end  
        
    def get_db_doc(server,token,doc,data_type='')
      res = RestClient.post("#{server}/api/get_db_doc", 
        {:api_token => token, :doc => doc, :data_type => data_type}.to_json, :content_type => :json).body
      data_type=='' ? JSON.parse(res) : res
    end

    def set_db_doc(server,token,doc,data={},data_type='')
      RestClient.post("#{server}/api/set_db_doc", 
       {:api_token => token, :doc => doc, :data => data, :data_type => data_type}.to_json, :content_type => :json)
    end
          
    def reset(server,token)
      RestClient.post("#{server}/api/reset",
        {:api_token => token}.to_json, :content_type => :json)
    end
    
  end
end