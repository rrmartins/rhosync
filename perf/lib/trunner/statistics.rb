module Trunner
  class Statistics
    include Logging
    
    def initialize(total_time,sessions)
      @sessions = sessions
      @rows = {} # row key is result.marker;
      @total_count = 0
      @total_time = total_time
    end
    
    def process
      @sessions.each do |session|
        session.results.each do |result|
          @rows[result.marker] ||= {}
          row = @rows[result.marker]
          row[:min] ||= 0.0
          row[:max] ||= 0.0
          row[:count] ||= 0
          row[:total_time] ||= 0.0
          row[:errors] ||= 0
          row[:min] = result.time if result.time < row[:min] || row[:min] == 0
          row[:max] = result.time if result.time > row[:max]
          row[:count] += 1.0
          row[:total_time] += result.time            
          row[:errors] += 1 if result.error
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
        logger.info "Request %-15s: min: %0.4f, max: %0.4f, avg: %0.4f, err: %d" % [marker, row[:min], row[:max], average(row), row[:errors]]
      end
      logger.info "Total Count      : #{@total_count}"
      logger.info "Total Time       : #{@total_time}"
      logger.info "Throughput(req/s): #{@total_count / @total_time}"
    end
  end
end