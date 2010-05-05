require 'json'
require 'mechanize'
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
  end
end

namespace :rhosync do
  include Rhosync::TaskHelper
  include RhosyncApi
  
  task :config do
    $settings = load_settings(File.join(ENV['PWD'],'settings','settings.yml'))
    env = (ENV['RHO_ENV'] || :development).to_sym  
    uri = URI.parse($settings[env][:syncserver])
    $url = "#{uri.scheme}://#{uri.host}"
    $url = "#{$url}:#{uri.port}" if uri.port && uri.port != 80
    $host = uri.host
    $port = uri.port
    $agent = Mechanize.new
    $appname = $settings[env][:syncserver].split('/').last
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
    RhosyncApi.reset($url,$token)
  end
  
  desc "Fetches current api token from rhosync"
  task :get_token => :config do
    login = ask "admin login: "
    password = ask "admin password: "
    $token = RhosyncApi.get_token($url,login,password)
    File.open($token_file,'w') {|f| f.write $token}
    puts "Token is saved in: #{$token_file}"
  end
  
  desc "Clean rhosync, get token, and create new user"
  task :clean_start => [:get_token, :reset, :get_token, :create_user]
  
  desc "Alias for `rake rhosync:stop; rake rhosync:start`"
  task :restart => [:stop, :start]
  
  desc "Creates and subscribes user for application in rhosync"
  task :create_user => :config do
    login = ask "new user login: "
    password = ask "new user password: "
    RhosyncApi.create_user($url,$appname,$token,login,password)
  end
  
  desc "Deletes the user from rhosync"
  task :delete_user => :config do
    login = ask "user to delete: "
    RhosyncApi.delete_user($url,$appname,$token,login)
  end
  
  # desc "Updates an existing user in rhosync"
  # task :update_user => :config do
  #   login = ask "login: "
  #   password = ask "password: "
  #   new_password = ask "new password: "
  #   post("/api/update_user", {:app_name => $appname, :api_token => $token,
  #     :login => login, :password => password, :attributes => {:new_password => new_password}})
  # end
  
  # desc "Reset source refresh time"
  # task :reset_refresh_time => :config do
  #   user = ask "user: "
  #   source_name = ask "source name: "
  #   post("/api/set_refresh_time", {:api_token => $token, :app_name => $appname,
  #     :user_name => user, :source_name => source_name})
  # end
  
  desc "Run rhosync source adapter specs"
  task :spec do
    files = File.join($app_basedir,'rhosync/spec/sources/*_spec.rb')
    Spec::Rake::SpecTask.new('rhosync:spec') do |t|
      t.spec_files = FileList[files]
      t.spec_opts = %w(-fs --color)
      t.rcov = true
      t.rcov_opts = ['--exclude', 'spec/*,gems/*']
    end
  end
  
  desc "Start rhosync server"
  task :start => :dtach_installed do
    if windows?
      puts 'Stop with Ctrl+C'
      sh "rackup config.ru"
    else
      puts 'Detach with Ctrl+\  Re-attach with rake rhosync:attach'
      sleep 2
      sh "dtach -A #{rhosync_socket} rackup config.ru -P #{rhosync_pid}"
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
end

load File.join(File.dirname(__FILE__),'..','..','tasks','redis.rake')