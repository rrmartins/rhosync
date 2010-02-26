module Trunner
  class Result
    attr_accessor :last_response,:time,:marker,:url,:verb,:error
    include Logging
    
    def initialize(marker,verb,url,thread_id,iteration)
      @marker,@verb,@url,@thread_id,@iteration = marker,verb,url,thread_id,iteration
      @time = 0
    end
    
    def code
      @last_response.code
    end
    
    def body
      @last_response.to_s
    end
    
    def cookies
      @last_response.cookies
    end
    
    def headers
      @last_response.headers
    end
    
    def verify_body(expected)
      expected,actual = JSON.parse(expected),JSON.parse(@last_response)
      if expected != actual
        logger.error "#{log_prefix} Verify error at: " + caller(1)[0].to_s
        logger.error "#{log_prefix} expected:\n#{expected.inspect}\n but got:\n#{actual.inspect}"
      end
    end
    
    def verify_code(expected)
      if expected != @last_response.code
        logger.error "#{log_prefix} Verify error at: " + caller(1)[0].to_s
        logger.error "#{log_prefix} expected: #{expected.inspect}\n but got: #{@last_response.code}"
      end
    end
    
    def verify_headers
      
    end
  end
end