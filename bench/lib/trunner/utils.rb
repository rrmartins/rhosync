module Trunner
  module Utils
    def compare(name1,s1,name2,s2)
      r1 = diff([],name1,s1,name2,s2)
      r2 = diff([],name2,s2,name1,s1)
      r1.size > r2.size ? r1 : r2
    end
    
    def diff(res,lname,lvalue,rname,rvalue,path=[])

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
    
    def compare_and_log(expected,actual,caller)
      if expected != actual
        logger.error "#{log_prefix} Verify error at: " + caller
        logger.error "#{log_prefix} Message diff: "
        compare(:expected,expected,:actual,actual).each do |diff|
          logger.error "#{log_prefix} Path: #{diff[:path].join('/')}"
          logger.error "#{log_prefix} Expected: #{diff[:expected].inspect}"
          logger.error "#{log_prefix} Actual: #{diff[:actual].inspect}"
        end
        true
      else
        false
      end
    end
  end
end