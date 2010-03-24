class Simple < Rhosync::Application
  class << self
    def authenticate(username,password,session)
      true # do some interesting authentication here...
    end
    
    def initializer
      super
    end
  end
end

Simple.initializer