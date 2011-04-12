# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rhosync/version"

Gem::Specification.new do |s|
  s.name        = "rhosync"
  s.version     = Rhosync::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rhomobile"]
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.email       = %q{dev@rhomobile.com}
  s.homepage    = %q{http://rhomobile.com/products/rhosync}
  s.summary     = %q{RhoSync Synchronization Framework}
  s.description = %q{RhoSync Synchronization Framework and related command-line utilities}

  s.rubyforge_project = nil

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {examples,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.default_executable = %q{rhosync}
  s.rubygems_version = %q{1.5.0}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  
  # s.add_dependency "sinatra"
end
