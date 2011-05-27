module Bench
  class Runner
    include Logging
    include Timer
    attr_reader :threads
    
    def initialize
      @threads = []
      @sessions = []
    end
    
    def test(concurrency,iterations,&block)
#      total_time = time do
#        0.upto(concurrency - 1) do |thread_id|
#          sleep rand(2)                    
#          threads << Thread.new(block) do |t|
#            0.upto(iterations - 1) do |iteration|
#              s = Session.new(thread_id, iteration)
#              @sessions << s
#              begin
#                yield Bench,s
#              rescue Exception => e
#                puts "error running script: #{e.inspect}"
#                puts e.backtrace.join("\n")
#              end
#            end
#          end
#        end
#        begin 
#          threads.each { |t| t.join }
#        rescue RestClient::RequestTimeout => e
#          bench_log "Request timed out #{e}"
#        end
#      end
#      Bench.sessions = @sessions
#      Bench.total_time = total_time      
      total_time = time do
        0.upto(concurrency - 1) do |thread_id|
          sleep rand(2)                    
          threads << Process.fork do
            pid = $$ # child process id
            0.upto(iterations - 1) do |iteration|
              s = Session.new(thread_id, iteration)
              begin
                yield Bench,s
              rescue Exception => e
                puts "error running script: #{e.inspect}"
                puts e.backtrace.join("\n")
              end
              File.open("/tmp/runner.#{pid}", "w+") { |f| Marshal.dump(s, f) }
            end
          end
        end
        begin 
          res = Process.waitall # returning an array of pid/status pairs
          res.each do |ps| 
            filename = "/tmp/runner.#{ps[0]}"
            s = Marshal.load(File.open(filename))
            @sessions << s
            File.delete(filename)
          end
        rescue RestClient::RequestTimeout => e
          bench_log "Request timed out #{e}"
        end
      end
      Bench.sessions = @sessions
      Bench.total_time = total_time
    end
  end
end  
  