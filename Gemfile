source "http://rubygems.org"

# Specify your gem's dependencies in rhosync.gemspec
gemspec

if defined?(JRUBY_VERSION)
  gem 'jdbc-sqlite3', :require => false
  gem 'activerecord'
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jruby-openssl'
  gem 'jruby-rack'
  gem 'warbler'
else
  gem 'sqlite3-ruby', '~> 1.2.5', :require => 'sqlite3'
end

group :development do
  gem 'rspec', '~> 2.5.0'
  gem 'rcov', '>= 0.9.8'
  gem 'faker', '>= 0.3.1'
  gem 'rack-test', '>= 0.5.3', :require => 'rack/test'
  gem 'thor', '>= 0.13.6'
end