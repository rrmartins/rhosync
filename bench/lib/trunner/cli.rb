require 'thor'

module Trunner
  class Cli < Thor
    include Logging
    desc "start path/to/trunner/script", "Start performance test"
    def start(script,login,password='')
      Trunner.admin_login = login
      Trunner.admin_password = password
      load(script)
      Statistics.new(Trunner.concurrency,Trunner.iterations,
        Trunner.total_time,Trunner.sessions).process.print_stats
      logger.info "Trunner completed..."
    end
  end
end