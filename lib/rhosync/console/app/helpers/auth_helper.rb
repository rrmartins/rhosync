class RhosyncConsole::Server
  helpers do

    def login_required
      session[:token].nil?
    end
    
    def report_error(message)
      session[:errors] = [] if session[:errors].nil?
      session[:errors] << message 
    end
      
    def verify_presence_of(param,message)
      report_error(message) if params[param].nil? or params[param].length == 0
    end
    
    def verify_format_of(param,message)
      report_error(message) if params[param].nil? or params[param] !~ /^(http|https):\/\//
    end
      
  end   
end