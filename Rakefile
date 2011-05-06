require 'rubygems'
require 'bundler/setup'
# Bundler.setup (:default, :development)

require 'yaml'
$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rhosync'

task :default => 'spec:all'
task :spec => 'spec:spec'

begin
  require 'rspec/core/rake_task'
  require 'rcov/rcovtask'
         
  TYPES = { 
    :spec   => 'spec/*_spec.rb',
    :perf   => 'spec/perf/*_spec.rb',
    :server => 'spec/server/*_spec.rb',
    :api    => 'spec/api/*_spec.rb',
    :bulk   => 'spec/bulk_data/*_spec.rb',
    :jobs   => 'spec/jobs/*_spec.rb',
    :stats => 'spec/stats/*_spec.rb',
    :ping   => 'spec/ping/*_spec.rb',
    :generator => 'spec/generator/*_spec.rb',
    :bench => 'bench/spec/*_spec.rb'
  }
 
  TYPES.each do |type,files|
    desc "Run specs in #{files}"
    RSpec::Core::RakeTask.new("spec:#{type}") do |t|
      t.rspec_opts = ["-b", "-c", "-fd"]
      t.pattern = FileList[TYPES[type]]
    end
  end

  desc "Run specs in spec/**/*_spec.rb "
  RSpec::Core::RakeTask.new('spec:all') do |t|
    t.rspec_opts = ["-b", "-c", "-fd"]
    t.pattern = FileList[TYPES.values]
    unless RUBY_VERSION =~ /1.9/ # FIXME: code coverage not working for Ruby 1.9 !!!
      t.rcov = true
      t.rcov_opts = ['--exclude', 'spec/*,gems/*,apps/*,bench/spec/*,json/*']    
    end
  end
  
  desc "Run doc generator - dumps out doc/protocol.html"
  RSpec::Core::RakeTask.new('doc') do |t|
    t.pattern = FileList['spec/doc/*_spec.rb']
    t.rcov = false
  end
  
rescue LoadError => e
  puts "rspec / rcov not available. Install with: "
  puts "gem install rspec rcov\n\n"
end

# desc "Build rhosync gem"
# task :gem => [ 'spec:all', 'clobber_spec:all', :gemspec, :build ]

desc "Load console environment"
task :console do
  if RedisRunner.running?   
    sh "irb -rubygems -r #{File.join(File.dirname(__FILE__),'lib','rhosync','server.rb')}"
  else
    puts "Redis is not running. Please start it by running 'rake redis:start' command."
  end  
end

desc "Run benchmark scripts"
task :bench do
  login = ask "login: "
  password = ask "password: "
  prefix = 'bench/scripts/'
  suffix = '_script.rb'
  list = ask "scripts(default is '*'): "
  file_list = list.empty? ? FileList[prefix+'*'+suffix] : FileList[prefix+list+suffix]
  file_list.each do |script|
    sh "bench/bench start #{script} #{login} #{password}"
  end
end

def ask(msg)
  print msg
  STDIN.gets.chomp
end

load 'tasks/redis.rake'
Bundler::GemHelper.install_tasks
