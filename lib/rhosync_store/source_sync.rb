module RhosyncStore
  class SourceSync
    attr_reader :adapter
    
    def initialize(source)
      @source = source
      raise InvalidArgumentError.new('Invalid source') if @source.nil?
      @adapter = SourceAdapter.create(@source)
    end
    
    # CUD Operations
    def create
      _process_cud('create')
    end
    
    def update
      _process_cud('update')
    end
    
    def delete
      _process_cud('delete')
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
    
    def process(client_id=nil,params=nil)
      return if _auth_op('login') == false
      
      self.create
      self.update
      self.delete

      if @source.poll_interval == 0 or 
        (@source.poll_interval != -1 and @source.refresh_time <= Time.now.to_i)
        self.read(client_id,params)
        @source.refresh_time = Time.now.to_i + @source.poll_interval
      end
      
      _auth_op('logoff')
    end
    
    private
    def _auth_op(operation,client_id=-1)
      edockey = client_id == -1 ? @source.document.get_source_errors_dockey :
        Document.new('cd',@source.app.id,Client.with_key(client_id).user_id,
          client_id,@source.name).get_search_errors_dockey
      begin
        @source.app.store.flash_data(edockey) if operation == 'login'
        @adapter.send operation
      rescue Exception => e
        Logger.error "SourceAdapter raised #{operation} exception: #{e}"
        @source.app.store.put_data(edockey,{"#{operation}-error"=>{'message'=>e.message}},true)
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
    
    def _process_client_cud(client_id,operation)
      errors,links,deletes,creates,dels = {},{},{},{},{}
      doc = Document.new('cd',@source.app.id,Client.with_key(client_id).user_id,
        client_id,@source.name)
      modified_doc = doc.send("get_#{operation}_dockey")
      modified = @source.app.store.get_data(modified_doc)
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
      { "get_key" => creates,         
        "get_delete_page_dockey" => deletes,
        "get_#{operation}_links_dockey" => links,
        "get_#{operation}_errors_dockey" => errors }.each do |key,value|
        @source.app.store.put_data(doc.send(key),value,true) unless value.empty?
      end
      unless operation != 'create' and creates.empty?
        @source.app.store.put_data(@source.document.get_key,creates,true)
      end
      if operation == 'delete'
        # Clean up deleted objects from master document and corresponding client document
        @source.app.store.delete_data(doc.get_key,dels)
        @source.app.store.delete_data(@source.document.get_key,dels)
      end
      # Record rest of queue (if something in the middle failed)
      if modified.empty?
        @source.app.store.flash_data(modified_doc)
      else
        @source.app.store.put_data(modified_doc,modified)
      end
      modified.size
    end
    
    def _process_cud(operation)
      # Pull client ids from modified queue and process them
      operation_key = @source.document.send("get_#{operation}_dockey")
      clients = @source.app.store.get_data(operation_key,Array)
      clients.each do |client_id|
        if _process_client_cud(client_id,operation) == 0
          clients.delete(client_id)
        end
      end
      if clients.empty?
        @source.app.store.flash_data(operation_key)
      else
        @source.app.store.put_data(operation_key,clients)
      end
    end
    
    # Read Operation; params are query arguments
    def _read(operation,client_id,params=nil)
      errorkey = nil
      begin
        if operation == 'search'
          sdoc = Document.new('cd',@source.app.id,Client.with_key(client_id).user_id,
            client_id,@source.name)
          errorkey = sdoc.get_search_errors_dockey
          compute_token sdoc.get_search_token_dockey
          @adapter.search params
          @adapter.save sdoc.get_search_dockey
        else
          errorkey = @source.document.get_source_errors_dockey
          params ? @adapter.query(params) : @adapter.query
          @adapter.sync
        end
        # operation,sync succeeded, remove errors
        @source.app.store.flash_data(errorkey)
      rescue Exception => e
        # store sync,operation exceptions to be sent to all clients for this source/user
        Logger.error "SourceAdapter raised #{operation} exception: #{e}"
        @source.app.store.put_data(errorkey,{"#{operation}-error"=>{'message'=>e.message}},true)
      end
      true
    end
  end
end
