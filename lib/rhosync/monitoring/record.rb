module Rhosync
  module Monitoring
    class Record
      class << self
        
        def add(metric, value = 1)
          # TODO: add record to metric, trim zset size if necessary
        end
        
        def set(metric, value)
          # TODO: set absolute value
        end
      
        def range(metric, start, finish = Time.now.to_i)
          # TODO: returns range of records based on start, finish
        end
        
        def resolution
          Object.const_get("#{metric.upper}_RECORD_RESOLUTION") || 60 #=> 1 minute aggregate
        end
        
        def record_size
          Object.const_get("#{metric.upper}_RECORD_SIZE") || 60 * 24 * 31 #=> 44640 minutes
        end
      end
    end
  end
end