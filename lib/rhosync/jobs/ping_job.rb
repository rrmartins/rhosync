require 'rhosync/ping'

module Rhosync
  module PingJob
    @queue = :ping
    
    # Perform a ping for all clients registered to a user
    def self.perform(params)
      user = User.load(params["user_id"])
      user.clients.members.each do |client_id|
        client = Client.load(client_id,{:source_name => '*'})
        params.merge!('device_port' => client.device_port,
          'device_pin' => client.device_pin)   
        if client.device_type and client.device_type.size > 0 and client.device_pin and client.device_pin.size > 0
          klass = Object.const_get(camelize(client.device_type.downcase))
          if klass
            params['vibrate'] = params['vibrate'].to_s
            klass.ping(params) 
          end
        else
          log "Skipping ping for non-registered client_id '#{client_id}'..."
        end
      end
    end
  end
end