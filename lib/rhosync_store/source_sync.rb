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
      return if _auth_op('login') == false
      
      res = _read('search',client_id,params)
      
      _auth_op('logoff')
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
    def _auth_op(operation)
      begin
        @adapter.send operation
        @source.app.store.flash_data(@source.document.get_source_errors_dockey) if operation == 'login'
      rescue Exception => e
        Logger.error "SourceAdapter raised #{operation} exception: #{e}"
        @source.app.store.put_data(@source.document.get_source_errors_dockey,
                                   {"#{operation}-error"=>{'message'=>e.message}},true)
        return false
      end
      true
    end
    
    def _process_cud(operation)
      errors,links,deletes,creates,dels = {},{},{},{},{}
      client_id = nil
      modified_doc = @source.document.send("get_#{operation}_dockey")
      modified = @source.app.store.get_data(modified_doc)
      # Process operation queue, one object at a time
      modified.each do |key,value|
        begin
          # Remove object from queue
          modified.delete(key)
          # Add id to object hash to forward to backend call
          value['id'] = key unless operation == 'create'
          # Extract meta-client_id so we can store it later
          client_id = value['rhomobile.rhoclient']
          value.delete('rhomobile.rhoclient')
          # Perform operation
          link = @adapter.send operation, value
          # Store object-id link for the client
          if operation == 'create'
            # If we have a link, store object in client document
            # Otherwise, store object for delete on client
            if link and link.is_a?(String)
              links[client_id] ||= {}
              links[client_id][key] = { 'l' => link }
              creates[client_id] ||= {}
              creates[client_id][link] = value
            else
              deletes[client_id] ||= {}
              deletes[client_id][key] = value
            end
          elsif operation == 'delete'
            dels[client_id] ||= {}
            dels[client_id][key] = value
          end
        rescue Exception => e
          Logger.error "SourceAdapter raised #{operation} exception: #{e}"
          errors[client_id] ||= {}
          errors[client_id][key] = value
          errors[client_id]["#{key}-error"] = {'message'=>e.message}
          break
        end
      end
      # Record operation results
      doc = Document.new('cd',@source.app.id,@source.user.id,'',@source.name)
      [ {:data => errors, :doc_key => "get_#{operation}_errors_dockey"}, 
        {:data => links, :doc_key => "get_#{operation}_links_dockey"},
        {:data => creates, :doc_key => "get_key"},
        {:data => deletes, :doc_key => "get_delete_page_dockey"} 
      ].each do |bucket|
        _record_operation_result(doc,operation,bucket[:doc_key],bucket[:data])
      end
      if operation == 'delete'
        # Clean up deleted objects from master document and corresponding client document
        dels.each do |client_id,data|
          doc.client_id = client_id
          @source.app.store.delete_data(doc.get_key,data)
          @source.app.store.delete_data(@source.document.get_key,data)
        end
      end
      # Record rest of queue (if something in the middle failed)
      @source.app.store.put_data(modified_doc,modified)
      true
    end
    
    def _record_operation_result(doc,operation,doc_key,result)
      result.each do |client_id,data|
        doc.client_id = client_id
        @source.app.store.put_data(doc.send(doc_key),data,true)
      end
    end
    
    # Read Operation; params are query arguments
    def _read(operation,client_id,params=nil)
      errorkey = nil
      begin
        if operation == 'search'
          sdoc = Document.new('cd',@source.app.id,@source.user.id,client_id,@source.name)
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
