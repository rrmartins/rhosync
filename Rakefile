require 'rubygems'
require 'resque/tasks'
require 'spec/rake/spectask'
require 'rcov/rcovtask'

$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rhosync'

task :default => :all

OPTS = { :spec_opts => ['-fs', '--color'], 
         :rcov      => true,
         :rcov_opts => ['--exclude', 'spec/*,gems/*,apps/*'] }
         
TYPES = { :spec   => 'spec/*_spec.rb',
          :perf   => 'spec/perf/*_spec.rb',
          :server => 'spec/server/*_spec.rb',
          :api    => 'spec/api/*_spec.rb',
          :bulk   => 'spec/bulk_data/*_spec.rb',
          :doc    => 'spec/doc/*_spec.rb',
          :all    => 'spec/**/*_spec.rb' } 
 
TYPES.each do |type,files|
  desc "Run #{type} specs"
  Spec::Rake::SpecTask.new(type) do |t|
    t.spec_files = FileList[TYPES[type]]
    t.spec_opts = OPTS[:spec_opts]
    t.rcov = OPTS[:rcov]
    t.rcov_opts = OPTS[:rcov_opts]
  end
end

desc "Load console environment"
task :console do
  sh "irb -rubygems -r rhosync.rb"
end

desc "Start server using config.ru"
task :start do
  sh "rackup config.ru"
end

task "resque:setup" do
  include Rhosync
  Rhosync.bootstrap do |rhosync|
    rhosync.blackberry_bulk_sync = true
  end
end
