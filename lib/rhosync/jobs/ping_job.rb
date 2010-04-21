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
        klass = Object.const_get(camelize(client.device_type.downcase))
        klass.ping(params) if klass
      end
    end
  end
end