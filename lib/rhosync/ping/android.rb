require 'net/https'
require 'uri'
module Rhosync
  class Android
    def self.ping(params)
      begin
        settings = get_config(Rhosync.base_directory)[Rhosync.environment]
        authtoken = settings[:authtoken]

        url = URI.parse('https://android.apis.google.com/c2dm/send')

        req = Net::HTTP::Post.new url.path, 'Authorization' => "GoogleLogin auth=#{authtoken}" 
        req.set_form_data c2d_message(params)

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        res = http.request(req)

      rescue Exception => error
        log "Error while sending ping: #{error}"
        raise error
      end
    end
    
    def self.c2d_message(params)
      params.reject! {|k,v| v.nil? || v.length == 0}
      data = {}
      data['registration_id'] = params['device_pin']
      data['collapse_key'] = (rand * 100000000).to_i.to_s
      data['data.do_sync'] = params['sources'] ? params['sources'].join(',') : ''
      data['data.alert'] = params['message'] if params['message']
      data['data.vibrate'] = params['vibrate'] if params['vibrate']
      data['data.sound'] = params['sound'] if params['sound']
      data['data.phone_id'] = params['phone_id'] if params['phone_id']
      data
    end
  end
end
