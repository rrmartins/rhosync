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
        
    def handle_api_error(error_message)
      begin
        yield
      rescue RestClient::Exception => re
        session[:errors] ||= []
        if re.response.body.nil? or re.response.body.length == 0
          session[:errors] << "#{error_message}: [#{re.http_code}] #{re.message}"  
        else
          session[:errors] << "#{error_message}: #{re.response.body}"
        end
      rescue Exception => e      
        session[:errors] ||= []
        session[:errors] << "#{error_message}: #{e.message}"
      end     
    end
    
    def doc_params
      doc_params = "source_id=#{CGI.escape(params[:source_id])}&user_id=#{CGI.escape(params[:user_id])}"
      doc_params += "&client_id=#{CGI.escape(params[:client_id])}" if params[:client_id] 
      doc_params
    end
    
    def doc_is_string
      params[:dbkey].ends_with?('token') or params[:dbkey].ends_with?('size')
    end        
  end   
end