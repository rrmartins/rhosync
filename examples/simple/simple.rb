class Simple
  class << self
    def authenticate(username,password,session)
      true # do some interesting authentication here...
    end
    
    # Add everything in vendor to load path
    # TODO: Integrate with 3rd party dependency management
    def initializer
      Dir["vendor/*"].each do |dir|
        $:.unshift File.join(dir,'lib')
      end
      require 'rhosync'
      require 'rhosync/server'
    end
  end
end

Simple.initializer

# Bootstrap Rhosync system
Rhosync.bootstrap(File.dirname(__FILE__))