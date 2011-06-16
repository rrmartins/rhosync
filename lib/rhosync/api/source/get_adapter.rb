Server.api :get_adapter do |params,user|
   {:adapter_url => Rhosync.appserver}.to_json
end