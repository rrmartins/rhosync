module Bench
  module Logging
    def log_prefix
      "[T:%03d|I:%03d]" % [@thread_id,@iteration]
    end
    
    def bench_log(msg)
      Rhosync.log msg
    end
  end
end