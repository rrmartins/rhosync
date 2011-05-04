require 'json'
require 'zip/zip'
require 'uri'
require File.join(File.dirname(__FILE__),'console','rhosync_api')

module Rhosync
  module TaskHelper
    def post(path,params)
      req = Net::HTTP.new($host,$port)
      resp = req.post(path, params.to_json, 'Content-Type' => 'application/json')
      print_resp(resp, resp.is_a?(Net::HTTPSuccess) ? true : false)
    end

    def print_resp(resp,success=true)
      if success
        puts "=> OK" 
      else
        puts "=> FAILED"
      end
      puts "=> " + resp.body if resp and resp.body and resp.body.length > 0
    end

    def archive(path)
      File.join(path,File.basename(path))+'.zip'
    end

    def ask(msg)
      print msg
      STDIN.gets.chomp
    end
    
    def load_settings(file)
      begin
        $settings = YAML.load_file(file)
      rescue Exception => e
        puts "Error opening settings file #{file}: #{e}."
        puts e.backtrace.join("\n")
        raise e
      end
    end
    
    def rhosync_socket
      "/tmp/rhosync.dtach"
    end
    
    def rhosync_pid
      "/tmp/rhosync.pid"
    end

    def windows?
      RUBY_PLATFORM =~ /(win|w)32$/
    end
    
    def thin?
      begin
        require 'thin'
        'rackup -s thin'
      rescue LoadError
        nil
      end
    end
    
    def mongrel?
      begin
        require 'mongrel'
        'rackup -s mongrel'
      rescue LoadError
        nil
      end
    end
    
    def report_missing_server
      msg =<<-EOF
Could not find 'thin' or 'mongrel' on your system.  Please install one:
  gem install thin
or
  gem install mongrel
EOF
      puts msg
      exit 1
    end
  end
end

namespace :rhosync do
  include Rhosync::TaskHelper
  include RhosyncApi
  
  task :config do
    $settings = load_settings(File.join('settings','settings.yml'))
    $env = (ENV['RHO_ENV'] || ENV['RACK_ENV'] || :development).to_sym  
    uri = URI.parse($settings[$env][:syncserver])
    $url = "#{uri.scheme}://#{uri.host}"
    $url = "#{$url}:#{uri.port}" if uri.port && uri.port != 80
    $host = uri.host
    $port = uri.port
    $appname = $settings[$env][:syncserver].split('/').last
    $token_file = File.join(ENV['HOME'],'.rhosync_token')
    $token = File.read($token_file) if File.exist?($token_file)
  end
  
  task :dtach_installed do
    if !windows? and (`which dtach` == '')
      puts "WARNING: dtach not installed or not on path, some tasks will not work!"
      puts "  Install with '[sudo] rake dtach:install'"
      exit
    end
  end
  
  desc "Reset the rhosync database (you will need to run rhosync:get_token afterwards)"
  task :reset => :config do
    confirm = ask " Are you sure? Resetting will remove all data!\n It will also return an error code to all\n existing devices when they connect! (yes/no): "
    if confirm == 'yes'
      RhosyncApi.reset($url,$token) 
      puts "Database reset."
    else
      puts "Cancelling."
    end
  end
  
  desc "Fetches current api token from rhosync"
  task :get_token => :config do
    password = ''
    login = ask "admin login: "
    begin
      system "stty -echo"
      password = ask "\nadmin password: "
      system "stty echo"
    rescue NoMethodError, Interrupt
      system "stty echo"
      exit
    end
    puts ''
    begin
      $token = RhosyncApi.get_token($url,login,password)
    rescue
      puts "Login failed."
      exit
    end
    File.open($token_file,'w') {|f| f.write $token}
    puts "Token is saved in: #{$token_file}"
  end
  
  desc "Clean rhosync, get token, and create new user"
  task :clean_start => [:get_token, :reset, :get_token, :create_user]
  
  desc "Alias for `rake rhosync:stop; rake rhosync:start`"
  task :restart => [:stop, :start]
  
  desc "Creates and subscribes user for application in rhosync"
  task :create_user => :config do
    password = ''
    login = ask "new user login: "
    begin
      system "stty -echo"
      password = ask "\nnew user password: "
      system "stty echo"
    rescue NoMethodError, Interrupt
      system "stty echo"
      exit
    end
    puts ''
    RhosyncApi.create_user($url,$token,login,password)
  end
  
  desc "Deletes a user from rhosync"
  task :delete_user => :config do
    login = ask "user to delete: "
    RhosyncApi.delete_user($url,$token,login)
  end
  
  desc "Deletes a device from rhosync"
  task :delete_device => :config do
    user_id = ask "device's user_id: "
    device_id = ask "device to delete: "
    RhosyncApi.delete_client($url,$token,user_id,device_id)
  end
  
  desc "Sets the admin password"
  task :set_admin_password => :get_token do
    new_pass,new_pass_confirm = '',''
    begin
      system "stty -echo"
      new_pass = ask "\nnew admin password: "
      new_pass_confirm = ask "\nconfirm new admin password: "
      system "stty echo"
    rescue NoMethodError, Interrupt
      system "stty echo"
      exit
    end
    if new_pass == ''
      puts "\nNew password can't be empty."
    elsif new_pass == new_pass_confirm
      puts ""
      post("/api/update_user", {:app_name => $appname, :api_token => $token,
        :attributes => {:new_password => new_pass}})
    else
      puts "\nNew password and confirmation must match."
    end
  end
  
  desc "Reset source refresh time"
  task :reset_refresh => :config do
    user = ask "user: "
    source_name = ask "source name: "
    RestClient.post("#{$url}/api/set_refresh_time", {:api_token => $token,
      :user_name => user, :source_name => source_name})
  end
  
  begin
    require 'spec/rake/spectask'
    require 'rcov/rcovtask' unless windows?

    desc "Run source adapter specs"
    task :spec do
      files = File.join('spec','sources','*_spec.rb')
      Spec::Rake::SpecTask.new('rhosync:spec') do |t|
        t.spec_files = FileList[files]
        t.spec_opts = %w(-fn -b --color)
        unless windows?
          t.rcov = true
          t.rcov_opts = ['--exclude', 'spec/*,gems/*']
        end
      end
    end
  rescue LoadError
    if windows?
      puts "rspec not available. Install it with: "
      puts "gem install rspec\n\n"
    else
      puts "rspec / rcov not available. Install it with: "
      puts "gem install rspec rcov\n\n"
    end
  end
  
  desc "Start rhosync server"
  task :start => :dtach_installed do
    cmd = thin? || mongrel? || report_missing_server
    if windows?
      puts 'Starting server in new window...'
      system("start cmd.exe /c #{cmd} config.ru")
    else
      puts 'Detach with Ctrl+\  Re-attach with rake rhosync:attach'
      sleep 2
      sh "dtach -A #{rhosync_socket} #{cmd} config.ru -P #{rhosync_pid}"
    end
  end
  
  desc "Stop rhosync server"
  task :stop => :dtach_installed do
    sh "cat #{rhosync_pid} | xargs kill -3" unless windows?
  end
  
  desc "Attach to rhosync console"
  task :attach => :dtach_installed do
    sh "dtach -a #{rhosync_socket}" unless windows?
  end
  
  desc "Launch the web console in a browser - uses :syncserver: in settings.yml"
  task :web => :config do
    windows? ? sh("start #{$url}") : sh("open #{$url}")
  end
  
  desc "Flush data store - WARNING: THIS REMOVES ALL DATA IN RHOSYNC"
  task :flushdb => :config do
    puts "*** WARNING: THIS WILL REMOVE ALL DATA FROM YOUR REDIS STORE ***"
    confirm = ask "Are you sure (please answer yes/no)? "
    if confirm == 'yes'
      Redis.new.flushdb
      puts "Database flushed..."
    else
      puts "Aborted..."
    end
  end
  
  desc "Generate a cryptographically secure secret session key"
  task :secret do
    begin
      require 'securerandom' 
      puts SecureRandom.hex(64)
    rescue LoadError
      puts "Missing secure random generator.  Try running `rake secret` in a rails application instead."
    end
  end
end

task :default => ['rhosync:spec']

load File.join(File.dirname(__FILE__),'..','..','tasks','redis.rake')