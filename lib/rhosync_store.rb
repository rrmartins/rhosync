require 'rubygems'
require 'redis'
require 'json'
require 'base64'
require 'zip/zip'
require 'rhosync_store/model'
require 'rhosync_store/source'
require 'rhosync_store/user'
require 'rhosync_store/api_token'
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

  # Server hook to initialize RhosyncStore
  def bootstrap(appdir)
    RhosyncStore.app_directory = appdir
    unless User.is_exist?('admin','login')
      admin = User.create({:login => 'admin', :admin => 1})
      admin.password = ''
      admin.create_token
    end
  end
  
  # Adds given path to top of ruby load path
  def add_adapter_path(path)
    check_and_add(path)
  end
  
  # Add path to load_path unless it has been added already
  def check_and_add(path)
    $:.unshift path unless $:.include?(path) 
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
  
  def unzip_file(file_dir,payload)
    uploaded_file = File.join(file_dir, payload[:upload_file][:filename])
    File.open(uploaded_file, 'wb') do |file|
      file.write(payload[:upload_file][:tempfile].read)
    end
    Zip::ZipFile.open(uploaded_file) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(file_dir,f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path)
      end
    end
    FileUtils.rm_f(uploaded_file)
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


