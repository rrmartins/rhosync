require 'rubygems'
require 'spec/rake/spectask'
require 'rcov/rcovtask'

task :default => :all

OPTS = { :spec_opts => %w(-fs --color), 
         :rcov      => true,
         :rcov_opts => ['--exclude', 'spec/*,gems/*'] }
         
TYPES = { :spec   => 'spec/*_spec.rb',
          :perf   => 'spec/perf/*_spec.rb',
          :server => 'spec/server/*_spec.rb',
          :api    => 'spec/api/*_spec.rb',
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