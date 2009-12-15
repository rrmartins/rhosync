require 'rubygems'
require 'redis'
require 'json'
require 'base64'
require 'rhosync_store/model'
require 'rhosync_store/source'
require 'rhosync_store/user'
require 'rhosync_store/app'
require 'rhosync_store/document'
require 'rhosync_store/store'
require 'rhosync_store/client'
require 'rhosync_store/client_sync'
require 'rhosync_store/source_adapter'
require 'rhosync_store/source_sync'
  
# Various module utilities for the store
module RhosyncStore
  class InvalidArgumentError < RuntimeError; end
  
  class << self
    attr_accessor :app_directory
  end
  
  # Adds given path to top of ruby load path
  def add_adapter_path(path)
    $:.unshift path
  end
  
  # Serializes oav to set element
  def setelement(obj,attrib,value)
    "#{obj}:#{attrib}:#{Base64.encode64(value.to_s)}"
  end
  
  # De-serializes oav from set element
  def getelement(element)
    res = element.split(':')
    [res[0], res[1], Base64.decode64(res[2])]
  end
  
  # Returns require-friendly filename for a class
  def underscore(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
  
  module_function :add_adapter_path
  
  # TODO: replace with real logger
  class Logger
    @@enabled = true
    
    class << self
      attr_accessor :enabled
      
      def info(*args)
        puts args.join unless args.nil? or @@enabled == false
      end
    
      def error(*args)
        puts args.join unless args.nil? or @@enabled == false
      end
    end
  end
end


