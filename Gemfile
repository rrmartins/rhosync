source "http://rubygems.org"

# Specify your gem's dependencies in rhosync.gemspec
gemspec

platforms :jruby do
  gem 'jdbc-sqlite3', :require => false
  gem 'dbi'
  gem 'dbd-jdbc', :require => 'dbd/Jdbc'
  gem 'jruby-openssl'
  gem 'jruby-rack'
  gem 'warbler'
end

platforms :ruby do
  gem 'sqlite3'
end

group :development do
  gem 'rspec', '~> 2.5.0'
  gem 'rcov', '>= 0.9.8'
  gem 'faker', '>= 0.3.1'
  gem 'rack-test', '>= 0.5.3', :require => 'rack/test'
  gem 'thor', '>= 0.13.6'
end