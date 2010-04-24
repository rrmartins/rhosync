require 'socket'
require 'openssl'
module Rhosync
  class Iphone
    def self.ping(params)
      settings = get_config(Rhosync.base_directory)[Rhosync.environment]
      cert_file = File.join(Rhosync.base_directory,settings[:iphonecertfile])
      cert = File.read(cert_file) if File.exists?(cert_file)
    	passphrase = settings[:iphonepassphrase]
    	host = settings[:iphoneserver]
    	port = settings[:iphoneport] 
      begin
        ssl_ctx = OpenSSL::SSL::SSLContext.new
    		ssl_ctx.key = OpenSSL::PKey::RSA.new(cert, passphrase)
    		ssl_ctx.cert = OpenSSL::X509::Certificate.new(cert)

    		socket = TCPSocket.new(host, port)
    		ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_ctx)
    		ssl_socket.sync = true
    		ssl_socket.connect

    		ssl_socket.write(apn_message(params))
    		ssl_socket.close
    		socket.close
  		rescue SocketError => error
  		  log "Error while sending ping: #{error}"
  		  raise error
  		end
    end

    # Generates APNS package
  	def self.apn_message(params)
  		data = {}
  		data['aps'] = {}
  		data['aps']['alert'] = params['message'] if params['message'] 
  		data['aps']['badge'] = params['badge'].to_i if params['badge']
  		data['aps']['sound'] = params['sound'] if params['sound']
  		data['aps']['vibrate'] = params['vibrate'] if params['vibrate']
  		data['do_sync'] = params['sources'] if params['sources']
  		json = data.to_json
  		"\0\0 #{[params['device_pin'].delete(' ')].pack('H*')}\0#{json.length.chr}#{json}"
  	end
  end
end