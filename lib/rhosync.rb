require 'redis'
require 'json'
require 'base64'
require 'zip/zip'
require 'rhosync/version'
require 'rhosync/document'
require 'rhosync/lock_ops'
require 'rhosync/model'
require 'rhosync/source'
require 'rhosync/user'
require 'rhosync/api_token'
require 'rhosync/app'
require 'rhosync/store'
require 'rhosync/client'
require 'rhosync/read_state'
require 'rhosync/client_sync'
require 'rhosync/source_adapter'
require 'rhosync/source_sync'
require 'rhosync/bulk_data'
require 'rhosync/indifferent_access'
  
# Various module utilities for the store
module Rhosync
  class InvalidArgumentError < RuntimeError; end
  class RhosyncServerError < RuntimeError; end
  
  class << self
    attr_accessor :base_directory, :app_directory, :data_directory, 
      :vendor_directory, :blackberry_bulk_sync, :redis
  end
  
  # Server hook to initialize Rhosync
  def bootstrap
    # Initialize Rhosync and Resque
    Rhosync.base_directory = nil
    Rhosync.app_directory = nil
    Rhosync.data_directory = nil
    Rhosync.vendor_directory = nil
    Rhosync.blackberry_bulk_sync = false
    yield self if block_given?
    Store.create(Rhosync.redis)
    Resque.redis = Store.db
    Rhosync.base_directory ||= File.join(File.dirname(__FILE__),'..')
    Rhosync.app_directory ||= File.join(Rhosync.base_directory,'apps')
    Rhosync.data_directory ||= File.join(Rhosync.base_directory,'data')
    Rhosync.vendor_directory ||= File.join(Rhosync.base_directory,'vendor')
    Rhosync.blackberry_bulk_sync ||= false
    # Add appdir and sources subdirectory
    # to load path if appdir exists
    if File.exist?(Rhosync.app_directory)
      Dir.entries(Rhosync.app_directory).each do |name|
        unless name == '..' || name == '.'
          appdir = File.join(Rhosync.app_directory,name)
          app_file = underscore(File.join(appdir,name+'.rb'))
          set_load_path(appdir)
          load app_file if File.exists?(app_file)
        end
      end
    end
    create_admin_user
    check_hsql_lib! if Rhosync.blackberry_bulk_sync
  end
  
  # Generate admin user on first load
  def create_admin_user
    unless User.is_exist?('admin')
      admin = User.create({:login => 'admin', :admin => 1})
      admin.password = ''
      admin.create_token
    end
  end

  # Sets up load path with ruby source for apps, sources, and vendor gems
  def set_load_path(appdir)
    check_and_add(appdir)
    check_and_add(File.join(appdir,'sources'))
    Dir["#{appdir}/vendor/*"].each do |dir|
      check_and_add(File.join(dir,'lib'))
    end
  end

  # Add path to load_path unless it has been added already
  def check_and_add(path)
    $:.unshift path unless $:.include?(path) 
  end
  
  def check_default_secret!(secret)
    if secret == '<changeme>'                        
      Logger.error "*"*60+"\n\n"
      Logger.error "WARNING: Change the session secret in config.ru from <changeme> to something secure."
      Logger.error "  i.e. running `rake secret` in a rails app will generate a secret you could use."
      Logger.error "\n\n"+"*"*60
    end
  end

  # Serializes oav to set element
  def setelement(obj,attrib,value)
    "#{obj}:#{attrib}:#{Base64.encode64(value.to_s)}"
  end

  # De-serializes oav from set element
  def getelement(element)
    res = element.split(':')
    [res[0], res[1], Base64.decode64(res[2].to_s)]
  end

  # Get random UUID string
  def get_random_uuid
    UUIDTools::UUID.random_create.to_s.gsub(/\-/,'')
  end

  # Generates new token (64-bit integer) based on # of 
  # microseconds since Jan 1 2009
  def get_token
    ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6).to_i
  end

  # Computes token for a single client request
  def compute_token(doc_key)
    token = get_token
    Store.put_value(doc_key,token)
    token.to_s
  end

  # Returns require-friendly filename for a class
  def underscore(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  # Taken from rails inflector
  def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
  end

  def check_hsql_lib!
    unless File.exists?(File.join(Rhosync.vendor_directory,'hsqldata.jar'))
      Logger.error "*"*60
      Logger.error ""
      Logger.error "WARNING: Missing vendor/hsqldata.jar, please install it for BlackBerry bulk sync support."
      Logger.error ""
      Logger.error "*"*60
    end
  end

  def unzip_file(file_dir,params)
    uploaded_file = File.join(file_dir, params[:filename])
    File.open(uploaded_file, 'wb') do |file|
      file.write(params[:tempfile].read)
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

  def lap_timer(msg,start)
    duration = timenow - start
    puts "#{msg}: #{duration}"
    timenow
  end

  def start_timer(msg='starting')
    puts "#{msg}"
    timenow
  end

  def timenow
    (Time.now.to_f * 1000)
  end
    
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