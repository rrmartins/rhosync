module Rhosync
  class ClientSync
    attr_accessor :source,:client,:p_size,:source_sync
    
    VERSION = 3
    
    def initialize(source,client,p_size=nil)
      raise ArgumentError.new('Unknown client') unless client
      raise ArgumentError.new('Unknown source') unless source
      @source,@client,@p_size = source,client,p_size ? p_size.to_i : 500
      @source_sync = SourceSync.new(@source)
    end
    
    def receive_cud(cud_params={},query_params=nil)
      _process_blobs(cud_params)
      processed = 0
      ['create','update','delete'].each do |op|
        key,value = op,cud_params[op]
        processed += _receive_cud(key,value) if value
      end
      @source_sync.process_cud(@client.id) if processed > 0
    end
    
    def send_cud(token=nil,query_params=nil)
      res = []
      if not _ack_token(token)
        res = resend_page(token)
      else
        @source_sync.process_query(query_params)
        res = send_new_page
      end
      _format_result(res[0],res[1],res[2],res[3])
    end
    
    def search(params)
      if params
        return _resend_search_result if params[:token] and params[:resend]
        if params[:token] and !_ack_search(params[:token]) 
          formatted_result = _format_search_result
          @client.flash_data('search*')
          return formatted_result
        end
      end
      _do_search(params)
    end
    
    def build_page
      res = {}
      yield res
      res.reject! {|key,value| value.nil? or value.empty?}
      res.merge!(_send_errors)
      res
    end
    
    def send_new_page
      compute_errors_page
      token,progress_count,total_count = '',0,0
      res = build_page do |r|
        progress_count,total_count,r['insert'] = compute_page
        r['delete'] = compute_deleted_page
        r['links'] = compute_links_page
        r['metadata'] = compute_metadata
      end
      if res['insert'] or res['delete'] or res['links']
        token = compute_token(@client.docname(:page_token))
      else
        _delete_errors_page 
      end    
      @client.put_data(:cd,res['insert'],true)      
      @client.delete_data(:cd,res['delete'])
      [token,progress_count,total_count,res]
    end
    
    # Resend token for a client, also sends exceptions
    def resend_page(token=nil)
      token,progress_count,total_count = '',0,0
      res = build_page do |r|
        r['insert'] = @client.get_data(:page)
        r['delete'] = @client.get_data(:delete_page)
        r['links'] = @client.get_data(:create_links_page)
        r['metadata'] = compute_metadata
        progress_count = @client.get_value(:cd_size).to_i
        total_count = @client.get_value(:total_count_page).to_i
      end
      token = @client.get_value(:page_token)
      [token,progress_count,total_count,res]
    end
    
    # Computes the metadata sha1 and returns metadata if client's sha1 doesn't 
    # match source's sha1
    def compute_metadata
      metadata_sha1,metadata = @source.lock(:metadata) do |s|
        [s.get_value(:metadata_sha1),s.get_value(:metadata)]
      end
      return if @client.get_value(:metadata_sha1) == metadata_sha1
      @client.put_value(:metadata_sha1,metadata_sha1)
      metadata
    end
    
    # Computes diffs between master doc and client doc, trims it to page size, 
    # stores page, and returns page as hash  
    def compute_page
      res,diffsize,total_count = @source.lock(:md) do |s| 
        res,diffsize = Store.get_diff_data(@client.docname(:cd),s.docname(:md),@p_size)
        total_count = s.get_value(:md_size).to_i
        [res,diffsize,total_count]
      end
      @client.put_data(:page,res)
      progress_count = total_count - diffsize
      @client.put_value(:cd_size,progress_count)
      @client.put_value(:total_count_page,total_count)
      [progress_count,total_count,res]
    end
    
    # Computes search result, updates md for source and cd for client with the result
    def compute_search
      client_res,diffsize = Store.get_diff_data(@client.docname(:cd),@client.docname(:search),@p_size)
      @client.put_data(:cd,client_res,true)
      @client.update_count(:cd_size,client_res.size)
      @client.put_data(:search_page,client_res)
      
      @source.lock(:md) do |s|
        source_diff,source_diffsize = Store.get_diff_data(s.docname(:md),@client.docname(:cd))
        s.put_data(:md,source_diff,true)
        s.update_count(:md_size,source_diff.size)
      end
      
      [client_res,client_res.size]
    end
    
    # Computes deleted objects (down to individual attributes) 
    # in the client document, trims it to page size, stores page, and returns page as hash      
    def compute_deleted_page
      res = {}
      delete_page_doc = @client.docname(:delete_page)
      page_size = @p_size
      diff = @source.lock(:md) { |s| Store.get_diff_data(s.docname(:md),@client.docname(:cd))[0] }
      diff.each do |key,value|
        res[key] = value
        value.each do |attrib,val|
          Store.db.sadd(delete_page_doc,setelement(key,attrib,val))
        end
        page_size -= 1
        break if page_size <= 0          
      end
      res
    end
    
    # Computes errors for client and stores a copy as errors page
    def compute_errors_page
      ['create','update','delete'].each do |operation|
        @client.lock("#{operation}_errors") do |c| 
          c.rename("#{operation}_errors","#{operation}_errors_page")
        end
      end
    end
    
    # Computes create links for a client and stores a copy as links page
    def compute_links_page
      @client.lock(:create_links) do |c| 
        c.rename(:create_links,:create_links_page)
        c.get_data(:create_links_page)
      end
    end
        
    class << self
      # Resets the store for a given app,client
      def reset(client)
        client.flash_data('*') if client
      end
    
      def search_all(client,params=nil)
        return [] unless params[:sources]
        res = []
        params[:sources].each do |source|
          s = Source.load(source['name'],{:app_id => client.app_id,
            :user_id => client.user_id})
          client.source_name = source['name']
          cs = ClientSync.new(s,client,params[:p_size])
          params[:token] = source['token'] if source['token']
          search_res = cs.search(params)
          res << search_res if search_res
        end
        res
      end
      
      def bulk_data(partition,client)
        name = BulkData.get_name(partition,client.user_id)
        data = BulkData.load(name)
        
        sources = client.app.partition_sources(partition,client.user_id)
        return {:result => :nop} if sources.length <= 0
        
        do_bd_sync = data.nil?
        do_bd_sync = (data.completed? and 
            (data.refresh_time <= Time.now.to_i or !data.dbfiles_exist?)) unless do_bd_sync
               
        if do_bd_sync  
          data.delete if data
          data = BulkData.create(:name => name,
            :app_id => client.app_id,
            :user_id => client.user_id,
            :sources => sources,
            :refresh_time => Time.now.to_i + Rhosync.bulk_sync_poll_interval)
          BulkData.enqueue("data_name" => name)
        end
        
        if data and data.completed? and data.dbfiles_exist?
          client.update_clientdoc(sources)
          {:result => :url, :url => data.url}
        elsif data
          {:result => :wait}
        end
      end
    end
    
    private
    def _resend_search_result
      res = @client.get_data(:search_page)
       _format_search_result(res,res.size)
    end
    
    def _ack_search(search_token)
      if @client.get_value(:search_token) != search_token
        @client.flash_data('search*')
        @client.put_data(:search_errors,
          {'search-error'=>{'message'=>'Search error - invalid token'}}
        )
        return false
      end
      true
    end
    
    def _do_search(params={})
      # call source adapter search unless client is sending token for ack
      search_params = params[:search] if params
      @source_sync.search(@client.id,search_params) if params.nil? or !params[:token]
      res,diffsize = compute_search
      formatted_res = _format_search_result(res,diffsize)      
      @client.flash_data('search*') if diffsize == 0
      formatted_res
    end
    
    def _format_search_result(res={},diffsize=nil)
      error = @client.get_data(:search_errors)
      if not error.empty?
        [ {'version'=>VERSION},
          {'source'=>@source.name},
          {'search-error'=>error} ]
      else  
        search_token = @client.get_value(:search_token)
        search_token ||= ''
        #res,diffsize = compute_search 
        return [] if res.empty?
        [ {'version'=>VERSION},
          {'token' => search_token},
          {'source'=>@source.name},
          {'count'=>res.size},
          {'insert'=>res} ]
       end
    end
    
    def _receive_cud(operation,params)
      return 0 if not ['create','update','delete'].include?(operation)
      @client.lock(operation) { |c| c.put_data(operation,params,true) }
      return 1
    end
    
    def _process_blobs(params)
      unless params[:blob_fields].nil?
        [:create,:update].each do |utype|
          objects = params[utype] || {}
          objects.each do |id,obj|
            params[:blob_fields].each do |field|
        		  blob = params["#{field}-#{id}"]
        		  obj[field] = @client.app.store_blob(obj,field,blob)
      		  end
        	end
      	end
      end
    end
    
    def _ack_token(token)
      stored_token = @client.get_value(:page_token)
      if stored_token 
        if token and stored_token == token
          @client.put_value(:page_token,nil)
          @client.flash_data(:create_links_page)
          @client.flash_data(:page)
          @client.flash_data(:delete_page)
          _delete_errors_page
          return true
        end
      else
        return true    
      end    
      false
    end
    
    def _delete_errors_page
      ['create','update','delete'].each do |operation|
        @client.flash_data("#{operation}_errors_page")
      end
    end
    
    def _send_errors
      res = {}
      ['create','update','delete'].each do |operation|
        res["#{operation}-error"] = @client.get_data("#{operation}_errors_page")
      end
      res["source-error"] = @source.lock(:errors) { |s| s.get_data(:errors) }
      res.reject! {|key,value| value.nil? or value.empty?}
      res
    end
    
    def _format_result(token,progress_count,total_count,res)
      count = 0
      count += res['insert'].length if res['insert']
      count += res['delete'].length if res['delete']
      [ {'version'=>VERSION},
        {'token'=>(token ? token : '')},
        {'count'=>count},
        {'progress_count'=>progress_count},
        {'total_count'=>total_count},
        res ]
    end
  end
end