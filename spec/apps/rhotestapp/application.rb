class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      session[:auth] = "delegated"
      raise RuntimeError.new('server error') if password == 'server error'
      raise LoginException.new('login exception') if password == 'wrongpass'
      return "different" if password == "diffuser"
      password == 'wrongpassnomsg' ? false : true
    end
    
    # Add hooks for application startup here
    # Don't forget to call super at the end!
    def initializer(path)
      super
    end
  end
end

Application.initializer(File.dirname(__FILE__))