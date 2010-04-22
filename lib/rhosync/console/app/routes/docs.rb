class RhosyncConsole::Server
  get '/docs' do
    @src_params = []
    handle_api_error("Can't load list of source attributes") do
      @src_params = RhosyncApi::get_source_params(session[:server],
        session[:app_name],session[:token],params[:source_id])
    end
    @docs = []
    @docs_name = ''
    @back_href = ''
    @doc_params = doc_params
    handle_api_error("Can't load list of the documents") do
      if params[:client_id]
        @docs_name = "client #{params[:client_id]}"
        @back_href = url("client?user_id=#{CGI.escape(params[:user_id])}&client_id=#{CGI.escape(params[:client_id])}") 
        @docs = RhosyncApi::list_client_docs(session[:server],
          session[:app_name],session[:token],params[:source_id],params[:client_id])
      else   
        if params[:user_id]=='*'      
          @docs_name = "app partition"
          @back_href = url('/')
        else
           @docs_name = "user #{params[:user_id]} partition"
           @back_href = url("user?user_id=#{CGI.escape(params[:user_id])}")
        end   
        @docs = RhosyncApi::list_source_docs(session[:server],
          session[:app_name],session[:token],params[:source_id],params[:user_id])
      end    
    end
    erb :docs
  end
  
  get '/doc' do
    @data = {}
    @is_string = doc_is_string
    handle_api_error("Can't load document") do
      @data = RhosyncApi::get_db_doc(session[:server],
        session[:token],params[:dbkey],@is_string ? :string : '')
    end
    @back_params = "source_id=#{CGI.escape(params[:source_id])}&user_id=#{CGI.escape(params[:user_id])}"
    @back_params += "&client_id=#{CGI.escape(params[:client_id])}" if params[:client_id] 
    @back_href = url("docs?#{doc_params}")
    erb :doc  
  end 
  
  get '/doc/clear' do
    is_string = doc_is_string    
    handle_api_error("Can't clear document") do
      RhosyncApi::set_db_doc(session[:server],session[:token],params[:dbkey],
        is_string ? '' : {}, is_string ? :string : '')
    end
    @result_name = "Clear result"
    @status = "Successfully cleared: [#{CGI.unescape(params[:dbkey])}]"
    @back_href = url("doc?#{doc_params}&dbkey=#{CGI.escape(params[:dbkey])}")
    erb :result
  end
  
  post '/doc/upload' do
    if params[:string]
      handle_api_error("Can't upload document") do
        RhosyncApi::set_db_doc(session[:server],session[:token],CGI.unescape(params[:doc]),params[:string],:string)
      end
    else  
      unless params[:file] &&
             (tmpfile = params[:file][:tempfile]) &&
             (name = params[:file][:filename])
        report_error "No file selected"
      else
        data = []
        while blk = tmpfile.read(65536)
          data << blk
        end
        handle_api_error("Can't upload document #{name.inspect}") do
          RhosyncApi::set_db_doc(session[:server],session[:token],CGI.unescape(params[:doc]),JSON.parse(data.join))
        end
      end
    end
    @result_name = "Upload result"
    @status = "Successfully uploadad data to: [#{CGI.unescape(params[:doc])}]"
    @back_href = url("doc?#{doc_params}&dbkey=#{params[:doc]}")
    erb :result
  end
   
end