module Rhosync
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
      save(@source.docname(:md))
    end
  
    def create(name_value_list); end

    def update(name_value_list); end

    def delete(name_value_list); end
    
    def ask(params=nil); end

    def logoff; end
    
    def save(docname)
      return if _result_nil?
      if @result.empty?
        Store.flash_data(docname)
      else
        Store.put_data(docname,@result)
      end
      @source.put_value(:md_size,@result.size)
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