module Trunner
  class Runner
    include Logging
    
    attr_reader :threads
    
    def initialize
      @threads = []
    end
    
    def test(concurrency,iterations,&block)
      concurrency.times do
        thread = Thread.new('foo') do |t|
          iterations.times do
            Session.new('var').test do |s|
              yield s
            end
          end
        end
        threads << thread
      end
      begin 
        threads.each { |t| t.join }
      rescue RestClient::RequestTimeout => e
        logger.info "Request timed out #{e}"
      end
      logger.info "Trunner completed..."
        # 
        # stats = Statistics.new(log_file)
        # stats.produce_statistics
    end    
  end
end  
  