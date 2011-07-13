require './rho_connect_install_constants'
require './rho_connect_install_debian'
require './rho_connect_install_yum'

module GetParams
  extend self
  
  # get_prefix
  # This method gets the directory into which the user would like to install
  # the software
  def get_prefix(options)
    valid_prefix = true
    if options[:prefix] && !options[:prefix].empty?
      prefix = options[:prefix]
      if !File.directory?("#{ options[:prefix] }")
        create_dir = ask_yes_or_no("#{ prefix } does not yet exist,\n" + 
                                   "would you like to create it?")
        create_dir = 'y' ? cmd("mkdir #{ prefix }") : valid_prefix = false 
      end #if
    else
      begin
        log_print "Where would you like to install?" +
                  "(blank for default of /opt/rhosync)"
        prefix = STDIN.readline.strip
        if prefix == ''
          prefix = Constants::DEFAULT_INSTALL_DIR
        end #if
        if !File.directory?(prefix)
          if File.file? prefix
            log_print "#{ prefix } is a non-dir file, try again."
            valid_prefix = false
          else
            create_dir = ask_yes_or_no("#{ prefix } does not yet exist, " + 
                                       "would you like to create it?")
            create_dir = 'y' ? cmd("mkdir #{ prefix }") : valid_prefix = false 
          end #if
        else
          valid_prefix = true
        end #if
      end while !valid_prefix
    end #if
    
    prefix
  end #get_prefix
  
  # get_flavor
  # determine whether running on a debian system or a yum system
  def get_flavor(options)
  get_cmd = ''
    Constants::SUPPORTED_PKG_MGRS.each do |mgr|
      if `which #{ mgr }` != ""
        get_cmd = mgr
      end #if
    end #do
    
    case get_cmd
    when 'apt-get'
      flavor = Debian.new(options)
    when 'yum'
      flavor = Yum.new(options)
    else
      log_print "Supported package manager not found"
      exit(3)
    end #case    
    
    flavor
  end #get_flavor
  
  private
  
  # ask_yes_or_no
  # gets a yes or no answer from the user
  def ask_yes_or_no(string)
    log_print string
    answer = ''
    begin
      answer = STDIN.readline.strip.downcase[0..0]
      if answer != 'y' && answer != 'n'
        log_print "Please answer yes or no..."
      end #if
    end while answer != 'y' && answer != 'n'
    
    answer
  end #ask_yes_or_no
  
end #GetParams
