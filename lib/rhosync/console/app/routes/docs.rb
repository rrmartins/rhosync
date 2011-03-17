class RhosyncConsole::Server
  def docs_render_page(contenturl)
    @currentpage = "Console"
    @initialcontent = contenturl
     @pagetitle = "Rhosync Console" #H1 title
     @locals = {
       :div => "main_box",
       :links => [ 
         { :url => url_path('/homepage'), :title => 'Info' },
         { :url => url_path('/doc/select'), :selected => true, :title => 'Server Document' },
         { :url => url_path('/users'), :title => 'Users' }
       ]
     }
     erb :content
  end

  def hash_to_params(inhash)
    outstring = "?"
    inhash.each do |k,v|
      outstring << "#{k}=#{CGI.escape(v)}&"
    end
    outstring
  end

  get '/docs' do
    if params[:xhr] or request.xhr?
    
      @src_params = []
      handle_api_error("Can't load list of source attributes") do
        @src_params = RhosyncApi::get_source_params(
          session[:server],session[:token],params[:source_id])
      end
      @docs = []
      @docs_name = ''
      @back_href = ''
      @doc_params = doc_params
      handle_api_error("Can't load list of the documents") do
        if params[:device_id]
          @docs_name = "device #{params[:device_id]}"
          @back_href = url_path("device?user_id=#{CGI.escape(params[:user_id])}&device_id=#{CGI.escape(params[:device_id])}") 
          @docs = RhosyncApi::list_client_docs(session[:server],session[:token],params[:source_id],params[:device_id])
        else   
          if params[:user_id]=='*'      
            @docs_name = "app partition"
            @back_href = url_path('/')
          else
             @docs_name = "user #{params[:user_id]} partition"
             @back_href = url_path("user?user_id=#{CGI.escape(params[:user_id])}")
          end   
          @docs = RhosyncApi::list_source_docs(session[:server],
            session[:token],params[:source_id],params[:user_id])
        end    
      end
      erb :docs, :layout => false
    else
      docs_render_page url_path("/docs" + hash_to_params(params))
      
    end
  end
  
  get '/doc/select' do
    if params[:xhr] or request.xhr?
      if params[:dbkey].nil?
        @dbkey = ''
        @data = {}
      else
        @dbkey = params[:dbkey]
        @is_string = doc_is_string      
        handle_api_error("Can't load document") do
          @data = RhosyncApi::get_db_doc(session[:server],
            session[:token],params[:dbkey],@is_string ? :string : '')
        end
      end
      erb :select_doc, :layout => false
    else
      docs_render_page url_path("/doc/select" + hash_to_params(params))
    end
  end
  
  get '/doc' do
    if params[:xhr] or request.xhr?
    
      @data = {}
      @is_string = doc_is_string
      handle_api_error("Can't load document") do
        @data = RhosyncApi::get_db_doc(session[:server],
          session[:token],params[:dbkey],@is_string ? :string : '')
      end
      @back_params = "source_id=#{CGI.escape(params[:source_id])}&user_id=#{CGI.escape(params[:user_id])}"
      @back_params += "&device_id=#{CGI.escape(params[:device_id])}" if params[:device_id] 
      @back_href = url_path("docs?#{doc_params}")
      erb :doc, :layout => false
    else
      docs_render_page url_path("/doc" + hash_to_params(params))
    end
        
  end 
  
  get '/doc/clear' do
    if params[:xhr] or request.xhr?
      is_string = doc_is_string    
      handle_api_error("Can't clear document") do
        RhosyncApi::set_db_doc(session[:server],session[:token],params[:dbkey],
          is_string ? '' : {}, is_string ? :string : '')
      end
      @result_name = "Clear result"
      @status = "Successfully cleared: [#{CGI.unescape(params[:dbkey])}]"
      @back_href = params[:user_id] ?
        url_path("doc?#{doc_params}&dbkey=#{CGI.escape(params[:dbkey])}") :
        url_path("doc/select?dbkey=#{CGI.escape(params[:dbkey])}")     
      erb :result, :layout => false
    else
       docs_render_page url_path("/doc/clear" + hash_to_params(params))
    end
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
    @back_href = params[:user_id] ?
      url_path("doc?#{doc_params}&dbkey=#{params[:doc]}") :
      url_path("doc/select?dbkey=#{params[:doc]}")
    erb :result
  end
   
end