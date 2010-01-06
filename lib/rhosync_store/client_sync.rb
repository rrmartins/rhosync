module RhosyncStore
  class ClientSync
    attr_accessor :source,:client,:p_size,:source_sync,:clientdoc
    
    VERSION = 3
    
    def initialize(source,client,p_size=nil)
      @source,@client,@p_size = source,client,p_size ? p_size.to_i : 500
      @source_sync = SourceSync.new(@source)
      @clientdoc = Document.new('cd',@source.app.id,@client.user_id,@client.id,@source.name)
    end
    
    def receive_cud(cud_params={},query_params=nil)
      cud_params.each do |key,value|
        _receive_cud(key,value)
      end
      @source_sync.process(query_params)
    end
    
    def send_cud(token=nil,query_params=nil)
      res = resend_page(token)
      return _format_result(res) unless res.empty?
      @source_sync.process(@client.id,query_params)
      res['insert'] = compute_page
      res['links'] = @source.app.store.get_data(@clientdoc.get_create_links_dockey)
      res['delete'] = compute_deleted_page
      @source.app.store.put_data(@clientdoc.get_key,res['insert'],true)      
      @source.app.store.delete_data(@clientdoc.get_key,res['delete'])
      res.reject! {|key,value| value.nil? or value.empty?}
      res['token'] = compute_token(@clientdoc.get_page_token_dockey) unless res.empty?
      res.merge!(_send_errors)
      _format_result(res)
    end
    
    def search(params)
      res = []
      return _resend_search_result(params[:search_token]) if params[:search_token] and params[:resend]
      _ack_search(params[:search_token]) if params[:search_token]
      res = _do_search(params[:search]) if params[:search]
      res
    end
    
    # Resend token for a client, also sends exceptions
    def resend_page(token=nil)
      res = {}
      if not _ack_token(token)     
        res['insert'] = @source.app.store.get_data(@clientdoc.get_page_dockey)
        res['links'] = @source.app.store.get_data(@clientdoc.get_create_links_dockey)
        res['delete'] = @source.app.store.get_data(@clientdoc.get_delete_page_dockey)
        res.reject! {|key,value| value.nil? or value.empty?}
        res['token'] = @source.app.store.get_value(@clientdoc.get_page_token_dockey) unless res.empty?
        res.merge!(_send_errors)
      end
      res
    end
    
    # Computes diffs between master doc and client doc, trims it to page size, 
    # stores page, and returns page as hash  
    def compute_page
      res,diffsize = _compute_diff(@clientdoc.get_key,@source.document.get_key)
      @source.app.store.put_data(@clientdoc.get_page_dockey,res)
      progress_count = @source.app.store.get_value(@source.document.get_datasize_dockey).to_i - diffsize
      
      @source.app.store.put_value(@clientdoc.get_datasize_dockey,progress_count)
      res
    end
    
    # Computes search hash
    def compute_search
      _compute_diff(@clientdoc.get_key,@clientdoc.get_search_dockey)
    end
    
    # Computes deleted objects (down to individual attributes) 
    # in the client documet, trims it to page size, stores page, and returns page as hash      
    def compute_deleted_page
      res = {}
      delete_page_key = @clientdoc.get_delete_page_dockey
      page_size = @p_size
      @source.app.store.get_diff_data(@source.document.get_key,@clientdoc.get_key).each do |key,value|
        res[key] = value
        value.each do |attrib,val|
          @source.app.store.db.sadd(delete_page_key,setelement(key,attrib,val))
        end
        page_size -= 1
        break if page_size <= 0          
      end
      res
    end
        
    class << self
      # Resets the store for a given app,client
      def reset(app,user,client)
        doc = Document.new('cd',app.id,user.id,client.id,'*')
        app.store.get_keys(doc.get_key).each do |key|
          app.store.flash_data(key)
        end
      end
    
      def search_all(client,params=nil)
        return [] unless params[:sources]
        res = []
        params[:sources].each do |source|
          s = Source.with_key(source)
          cs = ClientSync.new(s,client,params[:p_size])
          search_res = cs.search(params)
          res << search_res if search_res
        end
        res
      end
    end
    
    private
    def _resend_search_result(search_token)
       _format_search_result
    end
    
    def _ack_search(search_token)
      token = @source.app.store.get_value(@clientdoc.get_search_token_dockey)
      if token == search_token
        @source.app.store.flash_data(@clientdoc.get_search_errors_dockey)
        @source.app.store.flash_data(@clientdoc.get_search_dockey)    
        @source.app.store.flash_data(@clientdoc.get_search_token_dockey)        
      end
    end
    
    def _do_search(params)
      @source_sync.search(@client.id,params)
      _format_search_result      
    end
    
    def _format_search_result
      error = @source.app.store.get_data(@clientdoc.get_search_errors_dockey)
      if not error.empty?
        [ {'version'=>VERSION},
          {'source'=>@source.name},
          {'search-error'=>error} ]
      else  
        search_token = @source.app.store.get_value(@clientdoc.get_search_token_dockey)
        search_token ||= ''
        res,search_size = compute_search 
        return [] if res.empty?
        [ {'version'=>VERSION},
          {'search_token' => search_token},
          {'source'=>@source.name},
          {'count'=>res.size},
          {'insert'=>res} ]
       end
    end
    
    def _compute_diff(srckey,dstkey)
      res = {}
      page_size = @p_size
      diff = @source.app.store.get_diff_data(srckey,dstkey)
      diff.each do |key,item|
        res[key] = item
        page_size -= 1
        break if page_size <= 0         
      end
      [res,diff.size]
    end
    
    def _receive_cud(operation,params)
      return if not ['create','update','delete'].include?(operation)
      source_dockey = @source.document.send "get_#{operation}_dockey"
      client_dockey = @clientdoc.send "get_#{operation}_dockey"
      @source.app.store.put_data(client_dockey,params,true)
      unless @source.app.store.ismember?(source_dockey,@client.id)
        @source.app.store.put_data(source_dockey,[@client.id],true)
      end
    end
    
    def _ack_token(token)
      stored_token = @source.app.store.get_value(@clientdoc.get_page_token_dockey)
      if stored_token 
        if token and stored_token == token
          @source.app.store.put_value(@clientdoc.get_page_token_dockey,nil)
          @source.app.store.flash_data(@clientdoc.get_create_links_dockey)
          @source.app.store.flash_data(@clientdoc.get_page_dockey)
          @source.app.store.flash_data(@clientdoc.get_delete_page_dockey)
          return true
        end
      else
        return true    
      end    
      false
    end
    
    def _send_errors
      res = {}
      ['create','update','delete'].each do |operation|
        res["#{operation}-error"] = @source.app.store.get_data(@clientdoc.send("get_#{operation}_errors_dockey"))
      end
      res["source-error"] = @source.app.store.get_data(@source.document.get_source_errors_dockey)
      res.reject! {|key,value| value.nil? or value.empty?}
      res
    end
    
    def _format_result(res)
      count = 0
      count += res['insert'].length if res['insert']
      count += res['delete'].length if res['delete']
      total_count = @source.app.store.get_value(@source.document.get_datasize_dockey).to_i
      progress_count = @source.app.store.get_value(@clientdoc.get_datasize_dockey).to_i
      token = res['token']
      res.delete('token')
      [ {'version'=>VERSION},
        {'token'=>(token ? token : '')},
        {'count'=>count},
        {'progress_count'=>progress_count},
        {'total_count'=>total_count}, 
        res ]
    end
  end
end