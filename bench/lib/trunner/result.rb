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
      expected,actual = JSON.parse(expected),JSON.parse(@last_response.to_s)
      if expected != actual
        logger.error "#{log_prefix} Verify error at: " + caller(1)[0].to_s
        logger.error "#{log_prefix} Message diff: "
        Result.compare(:expected,expected,:actual,actual).each do |diff|
          logger.error "#{log_prefix} Path: #{diff[:path].join('/')}"
          logger.error "#{log_prefix} Expected: #{diff[:expected].inspect}"
          logger.error "#{log_prefix} Actual: #{diff[:actual].inspect}"
        end
        #logger.error "#{log_prefix} expected:\n#{expected.inspect}\n but got:\n#{actual.inspect}"
        @verification_error = true
      end
    end
    
    def verify_code(expected)
      if expected != @last_response.code
        logger.error "#{log_prefix} Verify error at: " + caller(1)[0].to_s
        logger.error "#{log_prefix} Code diff: "
        logger.error "#{log_prefix} expected: #{expected.inspect}"
        logger.error "#{log_prefix} but got:  #{@last_response.code}"
        @verification_error = true
      end
    end
    
    def verify_headers
      
    end
    
    def self.compare(name1,s1,name2,s2)
      r1 = diff([],name1,s1,name2,s2)
      r2 = diff([],name2,s2,name1,s1)
      r1.size > r2.size ? r1 : r2
    end
    
    def self.diff(res,lname,lvalue,rname,rvalue,path=[])

      return res if lvalue == rvalue
      
      if lvalue.is_a?(Array) and rvalue
        lvalue.each_index do |index| 
          p = Array.new(path)
          p << index
          diff(res,lname,lvalue[index],rname,rvalue.at(index),p)
        end                
      elsif lvalue.is_a?(Hash) and rvalue
        lvalue.each do |key,value| 
          p = Array.new(path)
          p << key
          diff(res,lname,value,rname,rvalue[key],p)
        end
      else            
        res << {:path=>path,lname=>lvalue,rname=>rvalue}
      end
      
      res 
    end
  end
end