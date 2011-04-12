module Bench
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
        session.results.each do |marker,results|
          results.each do |result|
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
            row[:verification_errors] += result.verification_error
            @total_count += 1
          end
        end
      end
      self
    end
    
    def average(row)
      row[:total_time] / row[:count]
    end
    
    def print_stats
      bench_log "Statistics:"
      @rows.each do |marker,row|
        bench_log "Request %-15s: min: %0.4f, max: %0.4f, avg: %0.4f, err: %d, verification err: %d" % [marker, row[:min], row[:max], average(row), row[:errors], row[:verification_errors]]
      end
      bench_log "State of MD        : #{Bench.verify_error == 0 ? true : false}"
      bench_log "Concurrency        : #{@concurrency}"
      bench_log "Iterations         : #{@iterations}"
      bench_log "Total Count        : #{@total_count}"
      bench_log "Total Time         : #{@total_time}"
      bench_log "Throughput(req/s)  : #{@total_count / @total_time}"
      bench_log "Throughput(req/min): #{(@total_count / @total_time) * 60.0}"
    end
  end
end