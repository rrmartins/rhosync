require 'rubygems'
require 'templater'

module Rhosync
  extend Templater::Manifold
  extend Rhosync
  
  desc <<-DESC
    Rhosync generator
  DESC
  
  class BaseGenerator < Templater::Generator
    def class_name
      name.gsub('-', '_').camel_case
    end
    
    def underscore_name
      Rhosync.underscore(name)
    end

    alias_method :module_name, :class_name
  end
  
  class AppGenerator < BaseGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates', 'application')
    end
    
    desc <<-DESC
      Generates a new rhosync application.
      
      Required:
        name        - application name
    DESC
    
    first_argument :name, :required => true, :desc => "application name"
    
    template :configru do |template|
      template.source = 'config.ru'
      template.destination = "#{name}/config.ru"
    end    
    
    template :settings do |template|
      template.source = 'settings/settings.yml'
      template.destination = "#{name}/settings/settings.yml"
    end
    
    template :application do |template|
      template.source = 'application.rb'
      template.destination = "#{name}/#{underscore_name}.rb"
    end
    
    template :rakefile do |template|
      template.source = 'Rakefile'
      template.destination = "#{name}/Rakefile"
    end
  end
  
  class SourceGenerator < BaseGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates', 'source')
    end

    desc <<-DESC
      Generates a new source adapter with the given name.
    DESC

    first_argument :name, :required => true, :desc => "model name"
    second_argument :attributes, :as => :array, :default => [], :required => false, :desc => "array of attributes (only string suppported right now)"

    template :config do |template|
      template.source = 'source_adapter.rb'
      template.destination = "lib/#{name.snake_case}.rb"
    end

  end
  
  
  add :app, AppGenerator
end