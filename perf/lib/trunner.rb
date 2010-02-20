#gem 'sevenwire-rest-client'
require 'rest_client'
require 'log4r'
require 'json'
$:.unshift File.dirname(__FILE__)
require 'trunner/timer'
require 'trunner/logging'
require 'trunner/result'
require 'trunner/session'
require 'trunner/runner'
require 'trunner/statistics'
require 'trunner/cli'

# Inspired by Trample: http://github.com/jamesgolick/trample

module Trunner
  class << self
    include Logging

    attr_accessor :concurrency, :iterations
    
    def config
      yield self
    end
  
    def test(&block)
      Runner.new.test(@concurrency,@iterations,&block)
    end
  end
end