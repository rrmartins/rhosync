module Trunner
  module Timer
    def time
      start = Time.now
      yield
      end_time = Time.now   
      end_time.to_f - start.to_f
    end
  end
end