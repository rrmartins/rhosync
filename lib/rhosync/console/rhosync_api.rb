require 'rest_client'
path = File.join(File.dirname(__FILE__),'..','..')
$:.unshift path
require 'rhosync'
include Rhosync

module RhosyncApi
  class << self

    def get_token(server,login,password)
      if directcall?(server)
        Server.get_api_token(nil,User.authenticate(login,password))
      else  
        do_login(server,login,password)
      end
    end
    
    def list_users(server,token)
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.list_users(nil,api_user(token)))
      else  
        JSON.parse(RestClient.post("#{server}/api/user/list_users",
            {:api_token => token}.to_json, :content_type => :json).body)
      end
    end
    
    def save_adapter(server,token,adapter_url)
      if directcall?(server) and verify_token(token)
        Server.save_adapter({:attributes => {'adapter_url' => adapter_url}},nil)
      else  
        RestClient.post("#{server}/api/source/save_adapter",
          {:api_token => token,:attributes => {:adapter_url => adapter_url}}.to_json, 
            :content_type => :json)
      end
    end
    
    def create_user(server,token,login,password)
      if directcall?(server) and verify_token(token)
        Server.create_user({:attributes => {'login' => login, 'password' => password}},nil)
      else  
        RestClient.post("#{server}/api/user/create_user",
          {:api_token => token,:attributes => {:login => login, :password => password}}.to_json, 
            :content_type => :json)
      end  
    end  

    def update_user(server,token,attributes)
      if directcall?(server) and verify_token(token)
        Server.update_user({:attributes => attributes},api_user(token))
      else  
        RestClient.post("#{server}/api/user/update_user",
          {:api_token => token,:attributes => attributes}.to_json, 
            :content_type => :json)
      end  
    end
    
    def delete_user(server,token,user_id)
      if directcall?(server) and verify_token(token)
        Server.delete_user({:user_id => user_id},nil)
      else
        RestClient.post("#{server}/api/user/delete_user",
          {:api_token => token, :user_id => user_id}.to_json, 
           :content_type => :json)
      end    
    end
  
    def list_clients(server,token,user_id)
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.list_clients({:user_id => user_id},nil))
      else
        JSON.parse(RestClient.post("#{server}/api/client/list_clients", 
          {:api_token => token, :user_id => user_id}.to_json, :content_type => :json).body)
      end
    end
    
    def create_client(server,token,user_id)
      if directcall?(server) and verify_token(token)
        Server.create_client({:user_id => user_id},nil)
      else  
        RestClient.post("#{server}/api/client/create_client",
          {:api_token => token, :user_id => user_id}.to_json, 
           :content_type => :json).body
      end
    end  
    
    def delete_client(server,token,user_id,client_id)
      if directcall?(server) and verify_token(token)
        Server.delete_client({:user_id => user_id,:client_id => client_id},nil)
      else
        RestClient.post("#{server}/api/client/delete_client",
          {:api_token => token, :user_id => user_id, 
           :client_id => client_id}.to_json, :content_type => :json)    
      end     
    end

    def get_client_params(server,token,client_id)
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.get_client_params({:client_id => client_id},nil))
      else
        JSON.parse(RestClient.post("#{server}/api/client/get_client_params", 
          {:api_token => token, :client_id => client_id}.to_json, :content_type => :json).body)
      end
    end
    
    def get_adapter(server,token)
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.get_adapter({},nil))
      else
        JSON.parse(RestClient.post("#{server}/api/source/get_adapter", 
          {:api_token => token}.to_json, :content_type => :json).body)
      end
    end
    
    def list_sources(server,token,partition='all')
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.list_sources({:partition_type => partition.to_s},nil))
      else  
        JSON.parse(RestClient.post("#{server}/api/source/list_sources", 
          {:api_token => token, :partition_type => partition}.to_json, :content_type => :json).body)
      end
    end

    def get_source_params(server,token,source_id)
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.get_source_params({:source_id => source_id},nil))
      else  
        JSON.parse(RestClient.post("#{server}/api/source/get_source_params", 
          {:api_token => token, :source_id => source_id}.to_json, :content_type => :json).body)
      end
    end
    
    def list_source_docs(server,token,source_id,user_id='*')
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.list_source_docs({:source_id => source_id, :user_id => user_id},nil))
      else  
        JSON.parse(RestClient.post("#{server}/api/source/list_source_docs", 
          {:api_token => token, :source_id => source_id, :user_id => user_id}.to_json, :content_type => :json).body)
      end
    end  
      
    def list_client_docs(server,token,source_id,client_id)
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.list_client_docs({:source_id => source_id, :client_id => client_id},nil))
      else  
        JSON.parse(RestClient.post("#{server}/api/client/list_client_docs", 
          {:api_token => token, :source_id => source_id, :client_id => client_id}.to_json, :content_type => :json).body)
      end    
    end  
    
    #TODO: figure out data_type programmatically     
    def get_db_doc(server,token,doc,data_type='')
      res = ""
      if directcall?(server) and verify_token(token)
        res = Server.get_db_doc({:doc => doc, :data_type => data_type},nil)
      else
        res = RestClient.post("#{server}/api/source/get_db_doc", 
          {:api_token => token, :doc => doc, :data_type => data_type}.to_json, :content_type => :json).body
      end 
      data_type=='' ? JSON.parse(res) : res
    end

    #TODO: figure out data_type programmatically     
    def set_db_doc(server,token,doc,data={},data_type='')
      if directcall?(server) and verify_token(token)
        Server.set_db_doc({:doc => doc, :data => data, :data_type => data_type},nil)
      else  
        RestClient.post("#{server}/api/source/set_db_doc", 
         {:api_token => token, :doc => doc, :data => data, :data_type => data_type}.to_json, :content_type => :json)
      end   
    end
          
    def reset(server,token)
      if directcall?(server) and verify_token(token)
        Server.reset({:api_token => token},api_user(token))
      else  
        RestClient.post("#{server}/api/admin/reset",
          {:api_token => token}.to_json, :content_type => :json)
      end
    end
    
    def ping(server,token,user_id,params)
      ping_params = {'api_token' => token, 'user_id' => user_id}
      [:message,:badge,:sound,:vibrate,:sources,:async].each do |part|
        part = part.to_s
        ping_params.merge!(part => params[part]) if params[part]
      end
      if directcall?(server) and verify_token(token)
        Server.ping(ping_params,nil)
      else  
        RestClient.post("#{server}/api/client/ping",ping_params.to_json, :content_type => :json)
      end  
    end

    def get_license_info(server,token)
      if directcall?(server) and verify_token(token)
        JSON.parse(Server.get_license_info(nil,nil))
      else  
        JSON.parse(RestClient.post("#{server}/api/admin/get_license_info",
          {:api_token => token}.to_json, :content_type => :json).body)
      end
    end
    
    def stats(server,token,params)
      if directcall?(server) and verify_token(token)
        Server.stats(params,api_user(token))
      else  
        RestClient.post("#{server}/api/admin/stats",
          {:api_token => token}.merge!(params).to_json, :content_type => :json).body
      end
    end
    
    private
    
    def do_login(server,login,password)
      RestClient.post("#{server}/api/admin/admin",
        {:login => login, :password => password}.to_json,
         :content_type => :json).body
    end
    
    def directcall?(server)
      server.nil? or server.length == 0
    end
    
    def api_user(token)
      ApiToken.load(token).user
    end
    
    def verify_token(token)
      raise ApiException.new(422, "Invalid/missing API user") unless api_user(token); true
    end
  end
  
  class Server
    def self.api(method_name,namespace = nil, &block)
      self.class.send(:define_method, method_name, &block)
    end  
  end
end

include RhosyncApi
Dir[File.join(File.dirname(__FILE__),'..','api','**','*.rb')].each { |api| load api }