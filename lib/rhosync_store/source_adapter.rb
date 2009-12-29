module RhosyncStore
  class SourceAdapterException < RuntimeError; end

  # raise this to cause client to be logged out during a sync
  class SourceAdapterLoginException < SourceAdapterException; end

  class SourceAdapterLogoffException < SourceAdapterException; end

  # raise these to trigger rhosync sending an error to the client
  class SourceAdapterServerTimeoutException < SourceAdapterException; end
  class SourceAdapterServerErrorException < SourceAdapterException; end

  class SourceAdapter
    attr_accessor :session
    
    def initialize(source,credential=nil)
      @source = source
    end
    
    # Returns an instance of a SourceAdapter by source name
    def self.create(source,credential=nil)
      adapter=nil
      if source
        begin
          source.name.strip! if source.name
          Logger.info "Creating class for #{source.name}"
          require underscore(source.name)
          adapter=(Object.const_get(source.name)).new(source,credential) 
        rescue Exception=>e
          Logger.error "Failure to create adapter from class #{source.name}: #{e.inspect.to_s}"
          #Logger.error e.backtrace.join("\n")
          raise e
        end
      end
      adapter
    end

    def login; end
  
    def query(params=nil); end
    
    def search(params=nil); end
    
    def sync
      save(@source.document.get_key)
    end
  
    def create(name_value_list); end

    def update(name_value_list); end

    def delete(name_value_list); end
    
    def ask(params=nil); end

    def logoff; end
    
    def save(dockey)
      return if _result_nil?
      if @result.empty?
        @source.app.store.flash_data(dockey)
      else
        @source.app.store.put_data(dockey,@result)
      end
      @source.app.store.put_value(@source.document.get_datasize_dockey,@result.size)
    end
  
    # only implement this if you want RhoSync to install a callback into your backend
    # def set_callback(notify_url)
    # end
  
    MSG_NIL_RESULT_ATTRIB = "You might have expected a synchronization but the @result attribute was 'nil'"
    
    protected
    def current_user
      @source.user
    end
  
    private 
    def _result_nil? #:nodoc:
      Logger.error MSG_NIL_RESULT_ATTRIB if @result.nil?
      @result.nil?
    end
  end
end