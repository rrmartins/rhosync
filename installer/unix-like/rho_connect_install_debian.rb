require './rho_connect_install_utilities'
require './rho_connect_install_constants'

include Utilities

class Debian
  attr_accessor :options
  
  def initialize(options)
    @@flavor = "Debian"
    @options = options
    @options[:pkg_mgr]  = 'apt-get -y'
    @options[:pkg_chkr] = 'dpkg -l'
  end #initialize
  
  # check_for_installed_software_only
  # This method runs checks against the software that must be installed.
  def check_for_installed_software_only
    check_all_installed
  end #check_for_installed_software_only
  
  # execute_installation
  # This method orchestrates the actual installation process
  def execute_installation
    #start logging
    @log = Logger.new(name_log_file(@options[:log_dir], Time.now))
    
    #gather necessary files
    download_and_decompress @options[:prefix]
    
    #start installing
    install_all_packages @options[:pkg_mgr]
    configure_passenger @options
    install_all_gems
    
    #remove downloaded tarballs
    cleanup options[:prefix]
  end #execute_installation
  
  # to_s
  # This method overrides the default to_s method
  def to_s
    string = "Debian Installation Parameters:\n"
    string << "\tPackage Manager\n"
    string << "\t\tapt-get\n"
    Constants::DEFAULTS.each do |key, val|
      string << "\t" + key + "\n"
      val.each do |field|
        string << "\t\t" + field + "\n"
      end #do
    end #do
    
    string
  end #to_s
    
end #Debian
