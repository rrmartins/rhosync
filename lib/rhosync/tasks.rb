require 'json'
require 'mechanize'
require 'zip/zip'
require 'uri'

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
  end
end

namespace :rhosync do
  include Rhosync::TaskHelper
  
  task :config do
    $settings = load_settings(File.join(File.dirname(__FILE__),'settings','settings.yml'))
    uri = URI.parse($settings[:syncserver])
    $url = "#{uri.scheme}://#{uri.host}"
    $url = "#{$url}:#{uri.port}" if uri.port && uri.port != 80
    $host = uri.host
    $port = uri.port
    $agent = Mechanize.new
    $appname = $settings[:syncserver].split('/').last
    $token_file = File.join(ENV['HOME'],'.rhosync_token')
    $token = File.read($token_file) if File.exist?($token_file)
  end
  
  desc "Reset the rhosync database (you will need to run rhosync:get_api_token afterwards)"
  task :reset => :config do
    $agent.post("#{$url}/api/reset",:api_token => $token)
  end
  
  desc "Fetches current api token from rhosync"
  task :get_api_token => :config do
    login = ask "admin login: "
    password = ask "admin password: "
    $agent.post("#{$url}/login", :login => login, :password => password)
    $token = $agent.post("#{$url}/api/get_api_token").body
    File.open($token_file,'w') {|f| f.write $token}
    puts "Token is saved in: #{$token_file}"
  end
  
  desc "Clean rhosync, get token, and create new user"
  task :clean_start => [:reset, :get_api_token, :create_user]
  
  desc "Creates and subscribes user for application in rhosync"
  task :create_user => :config do
    login = ask "new user login: "
    password = ask "new user password: "
    post("/api/create_user", {:app_name => $appname, :api_token => $token,
      :attributes => {:login => login, :password => password}})
  end
  
  desc "Updates an existing user in rhosync"
  task :update_user => :config do
    login = ask "login: "
    password = ask "password: "
    new_password = ask "new password: "
    post("/api/update_user", {:app_name => $appname, :api_token => $token,
      :login => login, :password => password, :attributes => {:new_password => new_password}})
  end
  
  desc "Reset source refresh time"
  task :reset_refresh_time => :config do
    user = ask "user: "
    source_name = ask "source name: "
    post("/api/set_refresh_time", {:api_token => $token, :app_name => $appname,
      :user_name => user, :source_name => source_name})
  end
  
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
  task :start do
    puts 'Detach with Ctrl+\  Re-attach with rake rhosync:attach'
    sleep 1
    command = "dtach -A #{rhosync_socket} rackup config.ru -P #{rhosync_pid}"
    sh command
  end
  
  desc "Stop rhosync server"
  task :stop do
    sh "cat #{rhosync_pid} | xargs kill -3"
  end
  
  desc "Attach to rhosync console"
  task :attach do
    sh "dtach -a #{rhosync_socket}"
  end
end

load File.join(File.dirname(__FILE__),'..','..','tasks','redis.rake')