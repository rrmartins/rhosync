module RhosyncStore
  class ClientSync
    attr_accessor :source,:client,:p_size,:source_sync
    
    VERSION = 3
    
    def initialize(source,client,p_size=nil)
      @source,@client,@p_size = source,client,p_size ? p_size.to_i : 500
      @source_sync = SourceSync.new(@source)
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
      res['links'] = @client.get_data(:create_links)
      res['delete'] = compute_deleted_page
      @client.put_data(:cd,res['insert'],true)      
      @client.delete_data(:cd,res['delete'])
      res.reject! {|key,value| value.nil? or value.empty?}
      res['token'] = compute_token(@client.docname(:page_token)) unless res.empty?
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
        res['insert'] = @client.get_data(:page)
        res['links'] = @client.get_data(:create_links)
        res['delete'] = @client.get_data(:delete_page)
        res.reject! {|key,value| value.nil? or value.empty?}
        res['token'] = @client.get_value(:page_token) unless res.empty?
        res.merge!(_send_errors)
      end
      res
    end
    
    # Computes diffs between master doc and client doc, trims it to page size, 
    # stores page, and returns page as hash  
    def compute_page
      res,diffsize = _compute_diff(@client.docname(:cd),@source.docname(:md))
      @client.put_data(:page,res)
      progress_count = @source.get_value(:md_size).to_i - diffsize
      @client.put_value(:cd_size,progress_count)
      res
    end
    
    # Computes search hash
    def compute_search
      _compute_diff(@client.docname(:cd),@client.docname(:search))
    end
    
    # Computes deleted objects (down to individual attributes) 
    # in the client documet, trims it to page size, stores page, and returns page as hash      
    def compute_deleted_page
      res = {}
      delete_page_doc = @client.docname(:delete_page)
      page_size = @p_size
      Store.get_diff_data(@source.docname(:md),@client.docname(:cd)).each do |key,value|
        res[key] = value
        value.each do |attrib,val|
          Store.db.sadd(delete_page_doc,setelement(key,attrib,val))
        end
        page_size -= 1
        break if page_size <= 0          
      end
      res
    end
        
    class << self
      # Resets the store for a given app,client
      def reset(client)
        client.flash_data('*')
      end
    
      def search_all(client,params=nil)
        return [] unless params[:sources]
        res = []
        params[:sources].each do |source|
          s = Source.load(source,{:app_id => client.app_id,
            :user_id => client.user_id})
          client.source_name = source
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
      token = @client.get_value(:search_token)
      if token == search_token
        @client.flash_data('search*')      
      end
    end
    
    def _do_search(params)
      @source_sync.search(@client.id,params)
      _format_search_result      
    end
    
    def _format_search_result
      error = @client.get_data(:search_errors)
      if not error.empty?
        [ {'version'=>VERSION},
          {'source'=>@source.name},
          {'search-error'=>error} ]
      else  
        search_token = @client.get_value(:search_token)
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
      diff = Store.get_diff_data(srckey,dstkey)
      diff.each do |key,item|
        res[key] = item
        page_size -= 1
        break if page_size <= 0         
      end
      [res,diff.size]
    end
    
    def _receive_cud(operation,params)
      return if not ['create','update','delete'].include?(operation)
      @client.put_data(operation,params,true)
      unless Store.ismember?(@source.docname(operation),@client.id)
        @source.put_data(operation,[@client.id],true)
      end
    end
    
    def _ack_token(token)
      stored_token = @client.get_value(:page_token)
      if stored_token 
        if token and stored_token == token
          @client.put_value(:page_token,nil)
          @client.flash_data(:create_links)
          @client.flash_data(:page)
          @client.flash_data(:delete_page)
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
        res["#{operation}-error"] = @client.get_data("#{operation}_errors")
      end
      res["source-error"] = @source.get_data(:errors)
      res.reject! {|key,value| value.nil? or value.empty?}
      res
    end
    
    def _format_result(res)
      count = 0
      count += res['insert'].length if res['insert']
      count += res['delete'].length if res['delete']
      total_count = @source.get_value(:md_size).to_i
      progress_count = @client.get_value(:cd_size).to_i
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