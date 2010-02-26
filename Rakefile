require 'resque/tasks'
require 'spec/rake/spectask'
require 'rcov/rcovtask'

$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rhosync'

task :default => :all

OPTS = { :spec_opts => ['-fs', '--color'], 
         :rcov      => true,
         :rcov_opts => ['--exclude', 'spec/*,gems/*,apps/*,bench/spec/*'] }
         
TYPES = { :spec   => 'spec/*_spec.rb',
          :perf   => 'spec/perf/*_spec.rb',
          :server => 'spec/server/*_spec.rb',
          :api    => 'spec/api/*_spec.rb',
          :bulk   => 'spec/bulk_data/*_spec.rb',
          :doc    => 'spec/doc/*_spec.rb', 
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

desc "Load console environment"
task :console do
  sh "irb -rubygems -r #{File.join(File.dirname(__FILE__),'lib','rhosync','server.rb')}"
end

desc "Start server using config.ru"
task :start do
  sh "rackup config.ru"
end

desc "Run benchmark scripts"
task :bench do
  login = ask "login: "
  password = ask "password: "
  file_list = FileList['bench/*_script.rb']
  file_list.each do |script|
    sh "bench/trunner start #{script} #{login} #{password}"
  end
end

task "resque:setup" do
  include Rhosync
end

def ask(msg)
  print msg
  STDIN.gets.chomp
end
