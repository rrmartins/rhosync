require 'net/http'
require 'uri'
module Rhosync
  class Blackberry
    def self.ping(params)
      begin
        settings = get_config(Rhosync.base_directory)[Rhosync.environment]
        host = settings[:mdsserver]
      	port = settings[:mdsserverport]
        
        headers = { "X-WAP-APPLICATION-ID" => "/",
                    "X-RIM-PUSH-DEST-PORT" => params['device_port'],
                    "CONTENT-TYPE" => 'multipart/related; type="application/xml"; boundary=asdlfkjiurwghasf'}
                    
        Net::HTTP.new(host,port).start do |http|
          request = Net::HTTP::Post.new('/pap',headers)
          request.body = pap_message(params)
          http.request(request)
        end

      rescue Exception => error
        Logger.error "Error while sending ping: #{error}"
  		  #Logger.error error.backtrace.join("\n")
  		  raise error
      end
    end
    
    def self.pap_message(params)
      data = "do_sync=" + (params['sources'] ? params['sources'].join(',') : "") + "\r\n"
      data << "show_popup=#{params['message']}\r\n" if params['message']
      data << "vibrate=#{params['vibrate']}\r\n" if params['vibrate']
      post_body = <<-DESC
--asdlfkjiurwghasf
Content-Type: application/xml; charset=UTF-8

<?xml version="1.0"?>
<!DOCTYPE pap PUBLIC "-//WAPFORUM//DTD PAP 2.0//EN" 
  "http://www.wapforum.org/DTD/pap_2.0.dtd" 
  [<?wap-pap-ver supported-versions="2.0"?>]>
<pap>
<push-message push-id="pushID:#{(rand * 100000000).to_i.to_s}" ppg-notify-requested-to="http://localhost:7778">

<address address-value="WAPPUSH=#{params['device_pin'].to_i.to_s(base=16).upcase}%3A100/TYPE=USER@rim.net"/>
<quality-of-service delivery-method="preferconfirmed"/>
</push-message>
</pap>
--asdlfkjiurwghasf
Content-Type: text/plain

#{data}
--asdlfkjiurwghasf--
DESC
      post_body.gsub!(/\n/,"\r\n")
    end
  end
end