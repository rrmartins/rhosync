class RhosyncConsole::Server
  helpers do
    def url(*path_parts)
      [ path_prefix, path_parts ].join("/").squeeze('/')
    end
    alias_method :u, :url

    def path_prefix
      request.env['SCRIPT_NAME']
    end

    def is_errors?
      session[:errors] and session[:errors].size > 0
    end
      
    def show_errors
      return '' unless session[:errors]
      res = []
      session[:errors].each do |error|
    	  res << "<p style=\"color:#800\">#{error}</p>"
    	end
    	session[:errors] = nil
    	res.join
    end
        
  end   
end