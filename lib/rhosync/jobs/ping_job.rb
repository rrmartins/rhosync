require 'rhosync/ping'

module Rhosync
  module PingJob
    @queue = :ping
    
    # Perform a ping for all clients registered to a user
    def self.perform(params)
      user = User.load(params["user_id"])
      device_pins = []
      phone_ids   = []
      user.clients.members.each do |client_id|
        client = Client.load(client_id,{:source_name => '*'})
        params.merge!('device_port' => client.device_port, 'device_pin' => client.device_pin, 'phone_id' => client.phone_id)
        send_push = false
        if client.device_type and client.device_type.size > 0
          # if client.phone_id and client.phone_id.size > 0
          #             unless phone_ids.include? client.phone_id   
          #               phone_ids << client.phone_id
          #               send_push = true
          #             end
          if client.device_pin and client.device_pin.size > 0
            puts 'found device id'
            unless device_pins.include? client.device_pin   
              device_pins << client.device_pin
              send_push = true
            end
          else
            log "Skipping ping for non-registered client_id '#{client_id}'..."
            next
          end
          puts "send push: #{send_push}"
          if send_push
            klass = Object.const_get(camelize(client.device_type.downcase)) 
            if klass
              params['vibrate'] = params['vibrate'].to_s
              klass.ping(params) 
            end
          else
            log "Dropping ping request for client_id '#{client_id}' because it's already in user's device pin or phone_id list."
          end
        else
          log "Skipping ping for non-registered client_id '#{client_id}'..."
        end
      end
    end
  end
end