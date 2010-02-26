require 'thor'

module Trunner
  class Cli < Thor
    desc "start path/to/trunner/script", "Start performance test"
    def start(script,login,password='')
      Trunner.login = login
      Trunner.password = password
      load(script)
    end
  end
end