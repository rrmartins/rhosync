require 'openssl'

module Rhosync
  class LicenseException < RuntimeError; end
  class LicenseSeatsExceededException < LicenseException; end
  
  class License
    attr_reader :rhosync_version, :licensee, :seats, :issued
    #attr_accessor :license

    # ships with rhosync
    RHO_PUBLICKEY = "99068e3a2708e6fe918252be8880eac539a1d2b2402651d75de5c7a2333a1cb2"
    CLIENT_DOCKEY = 'rho_client_count'

    def initialize
      begin
        settings = Rhosync.get_config(Rhosync.base_directory)[Rhosync.environment]
        @license = IO.read(File.join(Rhosync.base_directory,settings[:licensefile])).strip
        _decrypt
      rescue Exception => e
        #puts e.backtrace.join('\n')
        raise LicenseException.new("Error verifying license.")
      end
    end
    
    def check_and_use_seat
      incr = false
      Store.lock(CLIENT_DOCKEY) do
        current = Store.get_value(CLIENT_DOCKEY)
        current = current ? current.to_i : 0
        if current < self.seats
          Store.put_value CLIENT_DOCKEY, current + 1
          incr = true
        end
      end
      unless incr
        msg = "WARNING: Maximum # of clients exceeded for this license."
        log msg; raise LicenseSeatsExceededException.new(msg)
      end
    end
    
    def free_seat
      Store.lock(CLIENT_DOCKEY) do
        current = Store.get_value(CLIENT_DOCKEY)
        current = current ? current.to_i : 0
        if current > 0
          Store.put_value CLIENT_DOCKEY, current - 1
        end
      end
    end
    
    def available
      current = Store.get_value(CLIENT_DOCKEY)
      current = current ? current.to_i : 0
      available = self.seats - current
      available > 0 ? available : 0
    end
      
    private

    def _decrypt
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-ecb")
      cipher.key = _extract_str(RHO_PUBLICKEY)
      cipher.decrypt

      decrypted = cipher.update(_extract_str(@license))
      decrypted << cipher.final
      parts = decrypted.split(',')
      @rhosync_version = parts[0].strip
      @licensee = parts[1].strip
      @seats = parts[2].strip.to_i
      @issued = parts[3].strip
    end

    def _extract_str(str)
      str.gsub(/(..)/){|h| h.hex.chr}
    end
  end
end
