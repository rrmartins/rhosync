
# Collection of methods for locking shared
# source documents when source_sync and client_sync
# need to access them
module LockOps
  def lock(doc)
    Store.lock(docname(doc)) do
      yield self
    end
  end
end

module SourceLocks
  # Update the bucket used by source sync to
  # process the cud sent by all clients
  def update_cud_bucket(operation,params,client)
    client.put_data(operation,params,true)
    unless Store.ismember?(docname(operation),client.id)
      put_data(operation,[client.id],true)
    end
  end
  
  # def get_client_cud_list(operation)
  #   get_data(operation,Array)
  # end
  # 
  # def finalize_cud_list(operation,clients)
  #   if clients.empty?
  #     flash_data(operation)
  #   else
  #     put_data(operation,clients)
  #   end
  # end
    
  # Returns diff and total_count for a client page
  # Locks on the source's md
  def get_client_diff_page(client,p_size)
    res,diffsize = Store.get_diff_data(client.docname(:cd),docname(:md),p_size)
    total_count = get_value(:md_size).to_i
    [res,diffsize,total_count]
  end
  
  # Returns diff for a client's delete page
  # Lock's on source's md
  def get_client_diff_delete_page(client)
    Store.get_diff_data(docname(:md),client.docname(:cd))[0]
  end
  
  # Locks errors document for a client
  def get_source_errors
    get_data(:errors)
  end

  # Returns metadata and metadata sha1 locked
  def get_metadata
    [get_value(:metadata_sha1),get_value(:metadata)]
  end  
  
  def put_creates_to_md(creates)
    put_data(:md,creates,true)
    update_count(:md_size,creates.size)
  end
  
  def delete_from_md(dels)
    delete_data(:md,dels)
    update_count(:md_size,-dels.size)
  end
end

module ClientLocks
  # Returns the links created by source sync for a client
  # Locks on the client's links doc
  def get_client_links_page
    rename(:create_links,:create_links_page)
    get_data(:create_links_page)
  end
  
  # Locks the client's error document for a given operation
  # so source sync doesn't modify it while client is sync'ing
  def get_client_errors_page(operation)
    rename("#{operation}_errors","#{operation}_errors_page")
  end
end