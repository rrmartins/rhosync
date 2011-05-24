Server.api :save_adapter do |params,user|
  Rhosync.appserver = params[:attributes]['adapter_url']
  puts "Adapter url saved"
end