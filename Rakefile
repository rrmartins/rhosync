require 'yaml'
$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rhosync'

task :default => 'spec:all'
task :spec => 'spec:spec'

begin
  require 'spec/rake/spectask'
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
    Spec::Rake::SpecTask.new("spec:#{type}") do |t|
      t.spec_files = FileList[TYPES[type]]
    end
  end

  desc "Run specs in spec/**/*_spec.rb "
  Spec::Rake::SpecTask.new('spec:all') do |t|
    t.spec_files = FileList[TYPES.values]
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec/*,gems/*,apps/*,bench/spec/*,json/*']
  end
  
  desc "Run doc generator - dumps out doc/protocol.html"
  Spec::Rake::SpecTask.new('doc') do |t|
    t.spec_files = FileList['spec/doc/*_spec.rb']
    t.rcov = false
  end
  
rescue LoadError => e
  puts "rspec / rcov not available. Install with: "
  puts "gem install rspec rcov\n\n"
end

desc "Build rhosync gem"
task :gem => [ 'spec:all', 'clobber_spec:all', :gemspec, :build ]

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rhosync"
    gemspec.summary = %q{RhoSync Synchronization Framework}
    gemspec.description = %q{RhoSync Synchronization Framework and related command-line utilities}
    gemspec.homepage = %q{http://rhomobile.com/products/rhosync}
    gemspec.authors = ["Rhomobile"]
    gemspec.email = %q{dev@rhomobile.com}
    gemspec.version = Rhosync::VERSION
    gemspec.files =  FileList["[A-Z]*", "{bench,bin,generators,lib,spec,tasks}/**/*"]

    # TODO: Due to https://www.pivotaltracker.com/story/show/3417862, we can't use JSON 1.4.3
    gemspec.add_dependency "json", "~>1.4.2"
    gemspec.add_dependency "sqlite3-ruby", "~>1.2.5"
    gemspec.add_dependency "rubyzip", "~>0.9.4"
    gemspec.add_dependency "uuidtools", ">=2.1.1"
    gemspec.add_dependency "redis", "~>2.1.1"
    gemspec.add_dependency "resque", "~>1.14.0"
    gemspec.add_dependency "rest-client", "~>1.6.1"
    gemspec.add_dependency "sinatra", "~>1.2"
    gemspec.add_dependency "templater", "~>1.0.0"
    gemspec.add_dependency "rake", ">=0.8.7"
    gemspec.add_development_dependency "jeweler", ">=1.4.0"
    gemspec.add_development_dependency "rspec", ">=1.3.0"
    gemspec.add_development_dependency "rcov", ">=0.9.8"
    gemspec.add_development_dependency "faker", ">=0.3.1"
    gemspec.add_development_dependency "rack-test", ">=0.5.3"
    gemspec.add_development_dependency "thor", ">=0.13.6"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: "
  puts "gem install jeweler\n\n"
end

namespace :rhosync do
  desc "Load console environment"
  task :console do
    if RedisRunner.running?   
      sh "irb -rubygems -r #{File.join(File.dirname(__FILE__),'lib','rhosync','server.rb')}"
    else
      puts "Redis is not running. Please start it by running 'rake redis:start' command."
    end  
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
