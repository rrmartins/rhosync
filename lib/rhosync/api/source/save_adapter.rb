Server.api :save_adapter, :source do |params,user|
  Rhosync.appserver = params[:attributes]['adapter_url']
end