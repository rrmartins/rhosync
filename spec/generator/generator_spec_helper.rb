require 'rubygems'
require 'rspec'
require 'templater/spec/helpers'
require 'rhosync'
require File.join(File.dirname(__FILE__),'..','..','generators','rhosync')

RSpec.configure do |config|
  config.include Templater::Spec::Helpers
end