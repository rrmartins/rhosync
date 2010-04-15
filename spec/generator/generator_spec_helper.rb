require 'templater/spec/helpers'
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync'
require File.join(File.dirname(__FILE__),'..','..','generators','rhosync')

Spec::Runner.configure do |config|
  config.include Templater::Spec::Helpers
end