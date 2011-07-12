# Inspired by rabbitmq.rake the Redbox project at http://github.com/rick/redbox/tree/master
require 'fileutils'
require 'open-uri'

def windows?
	RUBY_PLATFORM =~ /(win|w)32$/
end

if windows?
	$redis_ver = "redis-2.2.11"
	$redis_zip = "C:/#{$redis_ver}.zip"
	$redis_dest = "C:/"
end

def redis_home
  ENV['REDIS_HOME'] || File.join($redis_dest,$redis_ver)
end

def mk_bin_dir(bin_dir)
  begin
    mkdir_p bin_dir unless File.exists?(bin_dir)
  rescue
    puts "Can't create #{bin_dir}, maybe you need to run command as root?"
    exit 1
  end
end
	
class RedisRunner
  
  def self.prefix
    "/usr/local/"
  end

  def self.redisdir
    "/tmp/redis/"
  end

  def self.redisconfdir
    server_dir = File.dirname(`which redis-server`)
    conf_file = "#{server_dir}/redis.conf"
    unless File.exists? conf_file
      conf_file = "#{server_dir}/redis.conf"
    end
    conf_file
  end

  def self.dtach_socket
    '/tmp/redis.dtach'
  end

  # Just check for existance of dtach socket
  def self.running?
    File.exists? dtach_socket
  end

  def self.start
  	if windows?
  		puts "Starting redis in a new window..."
  		sh "start #{File.join(redis_home,'redis-server')} #{File.join(redis_home,'redis.conf')}" rescue
  			"redis-server not installed on your path, please run 'rake redis:install' first."
		else
      puts 'Detach with Ctrl+\  Re-attach with rake redis:attach'
      sleep 1
      command = "dtach -A #{dtach_socket} redis-server #{redisconfdir}"
      sh command
    end
  end

  def self.attach
    exec "dtach -a #{dtach_socket}"
  end

  def self.stop
    Redis.new.shutdown rescue nil
  end

end

namespace :redis do

  desc 'About redis'
  task :about do
    puts "\nSee http://redis.io/ for information about redis.\n\n"
  end

  desc 'Start redis'
  task :start do
    RedisRunner.start
  end

  desc 'Stop redis'
  task :stop do
    RedisRunner.stop
  end

  desc 'Restart redis'
  task :restart do
    RedisRunner.stop
    RedisRunner.start
  end

  desc 'Attach to redis dtach socket'
  task :attach do
    RedisRunner.attach
  end

  desc 'Install the latest verison of Redis from Github (requires git, duh)'
  task :install => [:about, :download, :make] do
  	unless windows?
	    ENV['PREFIX'] and bin_dir = "#{ENV['PREFIX']}/bin" or bin_dir = "#{RedisRunner.prefix}bin"
	    
	    mk_bin_dir(bin_dir)
	    
	    %w(redis-benchmark redis-cli redis-server).each do |bin|
	      sh "cp /tmp/redis/src/#{bin} #{bin_dir}"
	    end
	
	    puts "Installed redis-benchmark, redis-cli and redis-server to #{bin_dir}"
	
	    ENV['PREFIX'] and conf_dir = "#{ENV['PREFIX']}/etc" or conf_dir = "#{RedisRunner.prefix}etc"
	    unless File.exists?("#{conf_dir}/redis.conf")
	      sh "mkdir #{conf_dir}" unless File.exists?("#{conf_dir}")
	      sh "cp /tmp/redis/redis.conf #{conf_dir}/redis.conf"
	      puts "Installed redis.conf to #{conf_dir} \n You should look at this file!"
	    end
    end
	end

  task :make do
  	unless windows?
      sh "cd #{RedisRunner.redisdir} && make clean"
      sh "cd #{RedisRunner.redisdir} && make"
    end
  end

  desc "Download package"
  task :download do
  	if windows?
      require 'net/http'
      require 'zip/zip'
      puts "Installing redis to #{redis_home}."

	    Net::HTTP.start("cloud.github.com") do |http|
	      resp = http.get("/downloads/dmajkic/redis/#{$redis_ver}-win32-win64.zip")
	      open($redis_zip, "wb") do |file|
	        file.write(resp.body)
	      end
	    end

	    Zip::ZipFile.open($redis_zip) do |zip_file|
	    	zip_file.each do |f|
	    		f_path = File.join(redis_home, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) { true }
    		end
    	end

    	FileUtils.mv Dir.glob(File.join(redis_home,'32bit','*')), redis_home
    	FileUtils.rm_rf File.join(redis_home, '64bit')
    	FileUtils.rm_f $redis_zip
    else
      sh 'rm -rf /tmp/redis/' if File.exists?("#{RedisRunner.redisdir}")
      sh 'git clone git://github.com/antirez/redis.git /tmp/redis -n'
      sh "cd #{RedisRunner.redisdir} && git reset --hard && git checkout 2.2.11"
    end
  end

end

namespace :dtach do

  desc 'About dtach'
  task :about do
    puts "\nSee http://dtach.sourceforge.net/ for information about dtach.\n\n"
  end

  desc 'Install dtach 0.8 from source'
  task :install => [:about] do
    unless windows?
      Dir.chdir('/tmp/')
      unless File.exists?('/tmp/dtach-0.8.tar.gz')
        require 'net/http'

        url = 'http://downloads.sourceforge.net/project/dtach/dtach/0.8/dtach-0.8.tar.gz'
        open('/tmp/dtach-0.8.tar.gz', 'wb') do |file| file.write(open(url).read) end
      end

      unless File.directory?('/tmp/dtach-0.8')
        system('tar xzf dtach-0.8.tar.gz')
      end

      ENV['PREFIX'] and bin_dir = "#{ENV['PREFIX']}/bin" or bin_dir = "#{RedisRunner.prefix}bin"
      
      mk_bin_dir(bin_dir)
	    
      Dir.chdir('/tmp/dtach-0.8/')
      sh 'cd /tmp/dtach-0.8/ && ./configure && make'
      sh "cp /tmp/dtach-0.8/dtach #{bin_dir}"

      puts "Dtach successfully installed to #{bin_dir}"
    end
  end
end