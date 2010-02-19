require 'thor'

module Trunner
  class Cli < Thor
    desc "start path/to/trunner/script", "Start performance test"
    def start(script)
      load(script)
    end
  end
end