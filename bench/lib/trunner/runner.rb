module Trunner
  class Runner
    include Logging
    include Timer
    attr_reader :threads
    
    def initialize
      @threads = []
      @sessions = []
    end
    
    def test(concurrency,iterations,&block)
      thread_id = 0
      total_time = time do
        concurrency.times do
          sleep rand(2)
          thread = Thread.new(block) do |t|
            tid, iteration = thread_id,0
            iterations.times do
              s = Session.new(tid,iteration)
              @sessions << s
              begin
                yield Trunner,s
              rescue Exception => e
                puts "error running script: #{e.inspect}"
              end    
              iteration += 1
            end
          end
          thread_id += 1    
          threads << thread
        end
        begin 
          threads.each { |t| t.join }
        rescue RestClient::RequestTimeout => e
          logger.info "Request timed out #{e}"
        end
      end
      Trunner.sessions = @sessions
      Trunner.total_time = total_time
    end    
  end
end  
  