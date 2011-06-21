Server.api :get_adapter, :source do |params,user|
   {:adapter_url => Rhosync.appserver}.to_json
end