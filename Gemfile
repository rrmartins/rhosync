source "http://rubygems.org"

# Specify your gem's dependencies in rhosync.gemspec
gemspec

platforms :jruby do
  gem 'trinidad'
  gem 'warbler'
end

group :development do
  gem 'rspec', '~> 2.6.0'
  gem 'rcov', '>= 0.9.8'
  gem 'ffaker', '~> 1.8.0'
  gem 'rack-test', '>= 0.5.3', :require => 'rack/test'
  gem 'thor', '>= 0.13.6'
  gem 'webmock', '~> 1.6.4'
end