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
      template.destination = "#{name}/#{name}.rb"
    end
  end
  
  add :app, AppGenerator
end