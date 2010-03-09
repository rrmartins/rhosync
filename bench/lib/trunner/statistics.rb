module Trunner
  class Statistics
    include Logging
    
    def initialize(concurrency,iterations,total_time,sessions)
      @sessions = sessions
      @rows = {} # row key is result.marker;
      @total_count = 0
      @total_time = total_time
      @concurrency,@iterations = concurrency,iterations
    end
    
    def process
      @sessions.each do |session|
        session.results.each do |marker,result|
          @rows[result.marker] ||= {}
          row = @rows[result.marker]
          row[:min] ||= 0.0
          row[:max] ||= 0.0
          row[:count] ||= 0
          row[:total_time] ||= 0.0
          row[:errors] ||= 0
          row[:verification_errors] ||= 0
          row[:min] = result.time if result.time < row[:min] || row[:min] == 0
          row[:max] = result.time if result.time > row[:max]
          row[:count] += 1.0
          row[:total_time] += result.time            
          row[:errors] += 1 if result.error
          row[:verification_errors] += 1 if result.verification_error
          @total_count += 1
        end
      end
      self
    end
    
    def average(row)
      row[:total_time] / row[:count]
    end
    
    def print_stats
      logger.info "Statistics:"
      @rows.each do |marker,row|
        logger.info "Request %-15s: min: %0.4f, max: %0.4f, avg: %0.4f, err: %d, verification err: %d" % [marker, row[:min], row[:max], average(row), row[:errors], row[:verification_errors]]
      end
      logger.info "Verify Error       : #{Trunner.verify_error}"
      logger.info "Concurrency        : #{@concurrency}"
      logger.info "Iterations         : #{@iterations}"
      logger.info "Total Count        : #{@total_count}"
      logger.info "Total Time         : #{@total_time}"
      logger.info "Throughput(req/s)  : #{@total_count / @total_time}"
      logger.info "Throughput(req/min): #{(@total_count / @total_time) * 60.0}"
    end
  end
end