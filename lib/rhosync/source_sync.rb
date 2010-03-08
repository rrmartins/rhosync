module Rhosync
  class SourceSync
    attr_reader :adapter
    
    def initialize(source)
      @source = source
      raise InvalidArgumentError.new('Invalid source') if @source.nil?
      raise InvalidArgumentError.new('Invalid app for source') unless @source.app
      @adapter = SourceAdapter.create(@source)
    end
    
    # CUD Operations
    def create(client_id)
      _process_cud('create',client_id)
    end
    
    def update(client_id)
      _process_cud('update',client_id)
    end
    
    def delete(client_id)
      _process_cud('delete',client_id)
    end
    
    # Read Operation; params are query arguments
    def read(client_id=nil,params=nil)
      _read('query',client_id,params)
    end
    
    def search(client_id=nil,params=nil)
      return if _auth_op('login',client_id) == false
      res = _read('search',client_id,params)
      _auth_op('logoff',client_id)
      res
    end
    
    def process(client_id,params=nil)
      return if _auth_op('login') == false
      
      self.create(client_id)
      self.update(client_id)
      self.delete(client_id)
            
      @source.if_need_refresh(client_id,params) do
        self.read(client_id,params)
      end
      
      _auth_op('logoff')
    end
    
    def refresh_source
      @source.if_need_refresh do
        return if _auth_op('login') == false
        self.read
        _auth_op('logoff')
      end
    end
    
    private
    def _auth_op(operation,client_id=-1)
      edockey = client_id == -1 ? @source.docname(:errors) :
        Client.load(client_id,{:source_name => @source.name}).docname(:search_errors)
      begin
        Store.flash_data(edockey) if operation == 'login'
        @adapter.send operation
      rescue Exception => e
        Logger.error "SourceAdapter raised #{operation} exception: #{e}"
        Store.put_data(edockey,{"#{operation}-error"=>{'message'=>e.message}},true)
        return false
      end
      true
    end
    
    def _process_create(client_id,key,value,links,creates,deletes)
      # Perform operation
      link = @adapter.create value
      # Store object-id link for the client
      # If we have a link, store object in client document
      # Otherwise, store object for delete on client
      if link
        links ||= {}
        links[key] = { 'l' => link.to_s }
        creates ||= {}
        creates[link.to_s] = value
      else
        deletes ||= {}
        deletes[key] = value
      end
    end
    
    def _process_update(client_id,key,value)
      # Add id to object hash to forward to backend call
      value['id'] = key
      # Perform operation
      @adapter.update value
    end
    
    def _process_delete(client_id,key,value,dels)
      value['id'] = key
      # Perform operation
      @adapter.delete value
      dels ||= {}
      dels[key] = value
    end
    
    def _process_cud(operation,client_id)
      errors,links,deletes,creates,dels = {},{},{},{},{}
      client = Client.load(client_id,{:source_name => @source.name})
      modified = client.get_data(operation)
      # Process operation queue, one object at a time
      modified.each do |key,value|
        begin
          # Remove object from queue
          modified.delete(key)
          # Call on source adapter to process individual object
          case operation
          when 'create'
            _process_create(client_id,key,value,links,creates,deletes)
          when 'update'
            _process_update(client_id,key,value)
          when 'delete'
            _process_delete(client_id,key,value,dels)
          end
        rescue Exception => e
          Logger.error "SourceAdapter raised #{operation} exception: #{e}"
          errors ||= {}
          errors[key] = value
          errors["#{key}-error"] = {'message'=>e.message}
          break
        end
      end
      # Record operation results
      { "delete_page" => deletes,
        "#{operation}_links" => links,
        "#{operation}_errors" => errors }.each do |doctype,value|
        client.put_data(doctype,value,true) unless value.empty?
      end
      unless operation != 'create' and creates.empty?
        client.put_data(:cd,creates,true)
        client.update_count(:cd_size,creates.size)
        @source.lock(:md) do |s| 
          s.put_data(:md,creates,true)
          s.update_count(:md_size,creates.size)
        end
      end
      if operation == 'delete'
        # Clean up deleted objects from master document and corresponding client document
        client.delete_data(:cd,dels)
        client.update_count(:cd_size,-dels.size)
        @source.lock(:md) do |s| 
          s.delete_data(:md,dels)
          s.update_count(:md_size,-dels.size)
        end
      end
      # Record rest of queue (if something in the middle failed)
      if modified.empty?
        client.flash_data(operation)
      else
        client.put_data(operation,modified)
      end
      modified.size
    end
    
    # Metadata Operation; source adapter returns json
    def _get_metadata
      if @adapter.respond_to?(:metadata)
        metadata = @adapter.metadata 
        if metadata
          @source.put_value(:metadata,metadata)
          @source.put_value(:metadata_sha1,Digest::SHA1.hexdigest(metadata))
        end
      end
    end
    
    # Read Operation; params are query arguments
    def _read(operation,client_id,params=nil)
      errordoc = nil
      begin
        if operation == 'search'
          client = Client.load(client_id,{:source_name => @source.name})
          errordoc = client.docname(:search_errors)
          compute_token(client.docname(:search_token))
          @adapter.search(params)
          @adapter.save(client.docname(:search))
        else
          errordoc = @source.docname(:errors)
          _get_metadata
          params ? @adapter.query(params) : @adapter.query
          @adapter.sync
        end
        # operation,sync succeeded, remove errors
        Store.lock(errordoc) do
          Store.flash_data(errordoc)
        end
      rescue Exception => e
        # store sync,operation exceptions to be sent to all clients for this source/user
        Logger.error "SourceAdapter raised #{operation} exception: #{e}"
        Store.lock(errordoc) do
          Store.put_data(errordoc,{"#{operation}-error"=>{'message'=>e.message}},true)
        end
      end
      true
    end
  end
end
