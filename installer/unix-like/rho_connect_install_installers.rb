require './rho_connect_install_constants'
require './rho_connect_install_checkers'

include Checkers

module Installers
  extend self

  # configure_passenger
  # This method installs items that were retrieved via wget as well as
  # passenger
  def configure_passenger(options)
    installs = 0
    print_header "Configuring Passenger"
    if options[:web_server] && !check_web_server_running
      if options[:web_server] == "apache2"
        print_header "Configuring Apache2 to work with Passenger"
      elsif options[:web_server] == "nginx"
        print_header "Configuring Nginx to work with Passenger"
      else
        log_print "That web server is not yet supported.  Sorry..."
      end #if
    end #if
    if options[:yes]
      cmd "yes | #{options[:ruby_dir]}/passenger-install-#{ options[:web_server] }-module"
    else
      cmd "#{options[:ruby_dir]}/passenger-install-#{ options[:web_server] }-module"
    end #if

    if installs == 0
      log_print "All prerequisites already installed."
    end #if
  end #configure_passenger
  
  # install_all_packages
  # This method installs all packages listed in the PACKAGES list defined
  # in the Constants file.
  def install_all_packages(get_cmd)
    print_header "Installing packages"
    Constants::PACKAGES.each do |pkg|
      install_package pkg, get_cmd unless check_package pkg == true
    end #do
    packages_not_found = check_all_packages
    if packages_not_found && !packages_not_found.empty?
      log_print packages_not_found
    else
      log_print "All packages installed correctly"
    end #if
  end #install_all_packages
  
  # install_package
  # This method installs the package passed with the determined get_cmd
  def install_package(pkg, get_cmd)
    cmd "#{ get_cmd } install #{ pkg }"  unless check_package pkg
  end #install_package
  
  # install_all_gems
  # This method installs all gems specified in the GEMS list defined in the
  # Constants file
  def install_all_gems
    gem_path = `which gem`
    Constants::GEMS.each do |gem|
      install_gem gem, gem_path
    end #do
  end #install_all_gems

  # install_gem
  # This method installs the given gem unless it is already installed
  def install_gem(gem, gem_path)
    cmd "#{ gem_path }gem install #{ gem } --no-ri --no-rdoc"  unless 
        check_gem gem
  end #install_gem
end #Installers
