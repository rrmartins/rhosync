
# Collection of methods for locking shared
# source documents when source_sync and client_sync
# need to access them
module SourceOps
  
  # CUD Processing
  
  # Update the bucket used by source sync to
  # process the cud sent by all clients
  def update_cud_bucket(operation,client)
    Store.lock(docname(operation)) do
      unless Store.ismember?(docname(operation),client.id)
        put_data(operation,[client.id],true)
      end
    end
  end
  
  
  # Metadata Processing
  
  # Returns metadata and metadata sha1 locked
  def get_metadata
    Store.lock(docname(:metadata)) do
      [get_value(:metadata_sha1),get_value(:metadata)]
    end
  end
end