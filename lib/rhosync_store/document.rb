module RhosyncStore
  class Document
    attr_accessor :doctype,:app_id,:user_id,:client_id,:source_name
    
    def initialize(doctype,app_id,user_id,client_id,source_name)
      @doctype,@app_id,@user_id,@client_id,@source_name = doctype,app_id,user_id,client_id,source_name
    end
    
    def get_page_dockey
      _get_doc("page")
    end
    
    def get_page_token_dockey
      _get_doc("page-token")
    end
    
    def get_search_dockey
      _get_doc("search")
    end
    
    def get_search_errors_dockey
      _get_doc("search-errors")
    end
  
    def get_search_token_dockey
      _get_doc("search-token")
    end  
    
    def get_delete_page_dockey
      _get_doc("delete-page")
    end
    
    def get_delete_dockey
      _get_doc("delete")
    end
    
    def get_delete_errors_dockey
      _get_doc("delete-errors")
    end
    
    def get_update_dockey
      _get_doc("update")
    end
    
    def get_update_errors_dockey
      _get_doc("update-errors")
    end
    
    def get_create_dockey
      _get_doc("create")
    end
    
    def get_create_errors_dockey
      _get_doc("create-errors")
    end
    
    def get_create_links_dockey
      _get_doc("create-links")
    end
    
    def get_source_errors_dockey
      _get_doc("source-errors")
    end

    def get_key
      "#{@doctype}:#{@app_id.to_s}:#{@user_id.to_s}:#{@client_id.to_s}:#{@source_name}"
    end
    
    def get_datasize_dockey
      _get_doc("datasize")
    end
    
    private
    def _get_doc(suffix)
      "#{@doctype}-#{suffix}:#{@app_id.to_s}:#{@user_id.to_s}:#{@client_id.to_s}:#{@source_name}"
    end
  end
end