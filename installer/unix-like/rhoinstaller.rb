require 'optparse'
require 'logger'
require 'time'
require './rho_connect_install_get_params'
require './rho_connect_install_constants'
require './rho_connect_install_utilities'

include GetParams
include Utilities

#make sure script is only run by root users
user = `whoami`.strip
if user != "root"
  puts "This installation must be performed by the root user"
  exit(2)
end #if
 
options = {}

optparse = OptionParser.new do|opts|
  options[:log_dir] = Constants::DEFAULT_INSTALL_DIR
  opts.on( '-l', '--log_dir LOGDIR', 'Write log in LOGDIR' ) do |dir|
    options[:log_dir] = dir
  end

  options[:offline] = nil
  opts.on( '-o', '--offline', 'Check that all necessary files are installed in /opt/rhosync if no prefix is specified.' ) do
    options[:offline] = true
  end
  
  options[:prefix] = Constants::DEFAULT_INSTALL_DIR
  opts.on( '-p', '--prefix PREFIX', 'Specify PREFIX as the installation directory' ) do |file|
    options[:prefix] = file
  end

  options[:ruby_dir] = "#{Constants::DEFAULT_INSTALL_DIR}rubyee/bin"
  opts.on( '-r', '--ruby-dir DIR', 'Specify DIR as the ruby execution directory' ) do |dir|
    options[:ruby_dir] = dir
  end

  options[:silent] = nil
  opts.on( '-s', '--silent', 'Perform installation with minimal output' ) do
    options[:silent] = true
  end
  
  options[:web_server] = "apache2"
  opts.on( '-w', '--web-server SERVER', 'Specify apache2 or nginx.  Default is apache2' ) do |server|
    options[:web_server] = server
  end
  
  options[:yes] = nil
  opts.on( '-y', 'Assume yes for all prompts' ) do
    options[:yes] = true
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
 
optparse.parse!
start_time = Time.parse(IO.readlines("time.txt").first)
log = Logger.new(name_log_file options[:log_dir], startTime)

#downcase all options hash string values
options.each do |key, val|
  options[key] = val.downcase if val.class == String
end #do

#Start installation process
#determine into what directory things will be installed
if !options[:yes]
  options[:prefix] = GetParams.get_prefix(options)
end #if

rho = GetParams.get_flavor(options)
if options[:offline]
  rho.check_for_installed_software_only
else
  rho.execute_installation
  rho.log_print "Installation Finished in #{rho.get_elapsed_time(start_time)}"
end #if
