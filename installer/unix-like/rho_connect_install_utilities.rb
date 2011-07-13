require 'readline'
require 'net/http'
require 'net/https'
require './rho_connect_install_constants'
require './rho_connect_install_installers'
require './rho_connect_install_checkers'
require './rho_connect_install_dnd'

include Installers
include Checkers
include DownloadAndDocompress

module Utilities
  extend self
  @log_file = ''

  # get_elapsed_time
  # This method returns the time since the given initial_time
  def get_elapsed_time(initial_time)
    #get time difference
    elapsed_time = Time.now - initial_time
    #determine if time is displayed in hours, minutes, or seconds
    if elapsed_time >= 3600
      elapsed_time /= 60
      time_units = "hours"
    elsif elapsed_time >= 60 && elapsed_time < 3600
      elapsed_time /= 60
      time_units = "minutes"
    else
      time_units = "seconds"
    end #if

    #round elapsed_time to 3 decimal values
    elapsed_time = (elapsed_time * 10**3).round.to_f / 10**3
    elapsed_time.to_s << " " + time_units
  end #get_elapsed_time
 
  # log_print
  # This method displays, in minutes, how long the installation process took
  def log_print(string)
    # if not in silent mode display string on STDOUT
    if !options[:silent]
      puts string
    end
    @log_file.puts string  unless @log_file == nil
  end #log_print

  private
  
  # cmd
  # This method issues the given system command and calls log_print for output
  def cmd(cmd)
    log_print cmd
    log_print `#{ cmd }`
  end #cmd
  
  # name_log_file
  # This method creates a new log_file FIle object to which the installation
  # process will print output
  def name_log_file(log_dir, time)
    @log_dir = log_dir
    if !File.directory? @log_dir
      make_dir @log_dir
    end
    @log_file = File.new("#{ log_dir }" +
                         "installog-#{ time.year }" +
                         "#{ time.month }" +
                         "#{ time.day }" +
                         "#{ time.hour }" +
                         "#{ time.min }" +
                         "#{ time.sec }", 'w')
    
    @log_file
  end #name_log_file
  
  # print_header
  # This method displays a header surrounded by '=' characters consisting of
  # the given string
  def print_header(string)
    header = ""
    border = "===="
    string.each_char { border << "=" }
    header << border + "\n"
    header << "= " + string + " =\n"
    header << border +"\n"
    log_print header
  end #print_header
  
  # cleanup
  # This method removes all compressed files from the installation directory
  # that were downloaded by this installation process
  def cleanup(prefix)
    print_header "Cleaning up"
    Constants::URLS.each do |url|
      file = get_tarball_name(url)
      if File.exists?("#{ prefix }#{ file }")
        cmd "rm #{ prefix }#{ file }"
      end #if
    end # do
    check_all_installed
  end #cleanup

  # make_dir
  # Creates the specified directory
  def make_dir(dir)
    cmd "mkdir #{dir}"
  end #make_dir
end #Utilities
