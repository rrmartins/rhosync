require 'set'

module Trunner
  class Result
    attr_accessor :last_response,:time,:marker,:url,:verb,:error,:verification_error
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
        logger.error "#{log_prefix} Diff: "
        Result.compare(expected,actual).each do |diff|
          logger.error "#{log_prefix} Path: #{diff[:path].join('/')} \nLValue:\t#{diff[:lvalue].inspect}\nRValue:\t#{diff[:rvalue].inspect}"
        end
        #logger.error "#{log_prefix} expected:\n#{expected.inspect}\n but got:\n#{actual.inspect}"
        @verification_error = true
      end
    end
    
    def verify_code(expected)
      if expected != @last_response.code
        logger.error "#{log_prefix} Verify error at: " + caller(1)[0].to_s
        logger.error "#{log_prefix} expected: #{expected.inspect}\n but got: #{@last_response.code}"
        @verification_error = true
      end
    end
    
    def verify_headers
      
    end
    
    def self.compare(s1,s2)
      r1 = diff([],s1,s2)
      r2 = diff([],s2,s1)
      r1.size > r2.size ? r1 : r2
    end
    
    def self.diff(res,lvalue,rvalue,path=[])

      return res if lvalue == rvalue
      
      if lvalue.is_a?(Array) and rvalue
        lvalue.each_index do |index| 
          p = Array.new(path)
          p << index
          diff(res,lvalue[index],rvalue.at(index),p)
        end                
      elsif lvalue.is_a?(Hash) and rvalue
        lvalue.each do |key,value| 
          p = Array.new(path)
          p << key
          diff(res,value,rvalue[key],p)
        end
      else            
        res << {:path=>path,:lvalue=>lvalue,:rvalue=>rvalue}
      end
      
      res 
    end
  end
end