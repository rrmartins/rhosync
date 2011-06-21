Server.api :save_adapter do |params,user|
  Rhosync.appserver = params[:attributes]['adapter_url']
end