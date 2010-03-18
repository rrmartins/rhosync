require 'thor'

module Bench
  class Cli < Thor
    include Logging
    desc "start path/to/bench/script", "Start performance test"
    def start(script,login,password='')
      Bench.admin_login = login
      Bench.admin_password = password
      load(script)
      Statistics.new(Bench.concurrency,Bench.iterations,
        Bench.total_time,Bench.sessions).process.print_stats
      logger.info "Bench completed..."
    end
  end
end