class <%=class_name%> < Rhosync::Application
  class << self
    def authenticate(username,password,session)
      true # do some interesting authentication here...
    end
    
    # Add hooks for application startup here
    # Don't forget to call super at the end!
    def initializer
      super
    end
  end
end

<%=class_name%>.initializer