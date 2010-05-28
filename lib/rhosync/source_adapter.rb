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
          require under_score(source.name)
          adapter=(Object.const_get(source.name)).new(source,credential) 
        rescue Exception=>e
          log "Failure to create adapter from class #{source.name}: #{e.inspect.to_s}"
          raise e
        end
      end
      adapter
    end

    def login; end
  
    def query(params=nil); end
    
    def search(params=nil); end
    
    def sync
      if @result and @result.empty?
        @source.lock(:md) do |s|
          s.flash_data(:md)
          s.put_value(:md_size,0)
        end
      else
        if @result
          Store.put_data(@tmp_docname,@result) 
          @stash_size += @result.size
        end  
        @source.lock(:md) do |s|
          s.flash_data(:md)
          Store.rename(@tmp_docname,s.docname(:md))
          s.put_value(:md_size,@stash_size)
        end
      end
    end
    
    def do_query(params=nil)
      @tmp_docname = @source.docname(:md) + get_random_uuid
      @stash_size = 0
      params ? self.query(params) : self.query
      self.sync
    end
    
    def stash_result
      return if @result.nil?
      Store.put_data(@tmp_docname,@result,true)
      @stash_size += @result.size
      @result = nil
    end
    
    def expire_bulk_data(partition = :user)
      name = BulkData.get_name(partition,current_user.login)
      data = BulkData.load(name)
      data.refresh_time = Time.now.to_i if data
    end
  
    def create(name_value_list); end

    def update(name_value_list); end

    def delete(name_value_list); end
    
    def ask(params=nil); end

    def logoff; end
    
    def save(docname)
      return if @result.nil?
      if @result.empty?
        Store.flash_data(docname)
      else
        Store.put_data(docname,@result)
      end
    end
    
    protected
    def current_user
      @source.user
    end
  end
end