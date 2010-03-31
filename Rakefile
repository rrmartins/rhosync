require 'yaml'
require 'resque/tasks'
require 'spec/rake/spectask'
require 'rcov/rcovtask'

$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rhosync'

task :default => :all

OPTS = { :spec_opts => ['-fs', '--color', '-b'], 
         :rcov      => true,
         :rcov_opts => ['--exclude', 'spec/*,gems/*,apps/*,bench/spec/*'] }
         
TYPES = { :spec   => 'spec/*_spec.rb',
          :perf   => 'spec/perf/*_spec.rb',
          :server => 'spec/server/*_spec.rb',
          :api    => 'spec/api/*_spec.rb',
          :bulk   => 'spec/bulk_data/*_spec.rb',
          :doc    => 'spec/doc/*_spec.rb', 
          :generator => 'spec/generator/*_spec.rb',
          :bench_spec => 'bench/spec/*_spec.rb'}
 
TYPES.each do |type,files|
  desc "Run #{type} specs"
  Spec::Rake::SpecTask.new(type) do |t|
    t.spec_files = FileList[TYPES[type]]
    t.spec_opts = OPTS[:spec_opts]
    t.rcov = OPTS[:rcov]
    t.rcov_opts = OPTS[:rcov_opts]
  end
end

desc "Run all specs"
Spec::Rake::SpecTask.new(:all) do |t|
  t.spec_files = FileList[TYPES.values]
  t.spec_opts = OPTS[:spec_opts]
  t.rcov = OPTS[:rcov]
  t.rcov_opts = OPTS[:rcov_opts]
end

desc "Build rhosync gem"
task :gem => [ :all, :gemspec, :build ]

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rhosync"
    gemspec.summary = %q{Rhosync Server}
    gemspec.description = %q{Rhosync Server and related command-line utilities for using Rhosync}
    gemspec.homepage = %q{http://rhomobile.com/products/rhosync}
    gemspec.authors = ["Rhomobile"]
    gemspec.version = Rhosync::VERSION
    gemspec.files =  FileList["[A-Z]*", "{bench,bin,doc,generators,lib,spec}/**/*"]

    gemspec.add_dependency "json", ">=1.2.3"
    gemspec.add_dependency "sqlite3-ruby", ">=1.2.5"
    gemspec.add_dependency "rubyzip", ">=0.9.4"
    gemspec.add_dependency "uuidtools", ">=2.1.1"
    gemspec.add_dependency "redis", ">=0.2.0"
    gemspec.add_dependency "resque", ">=1.6.0"
    gemspec.add_dependency "sinatra", ">=0.9.2"
    gemspec.add_dependency "templater", ">=1.0.0"
    gemspec.add_development_dependency "jeweler", ">=1.4.0"
    gemspec.add_development_dependency "rspec", ">=1.3.0"
    gemspec.add_development_dependency "rcov", ">=0.9.8"
    gemspec.add_development_dependency "faker", ">=0.3.1"
    gemspec.add_development_dependency "rack-test", ">=0.5.3"
    gemspec.add_development_dependency "mechanize", ">=1.0.0"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: "
  puts "gem install jeweler"
end

desc "Load console environment"
task :console do
  sh "irb -rubygems -r #{File.join(File.dirname(__FILE__),'lib','rhosync','server.rb')}"
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

task "resque:setup" do
  require 'init'
end

def ask(msg)
  print msg
  STDIN.gets.chomp
end

load 'tasks/redis.rake'
