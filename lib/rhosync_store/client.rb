module RhosyncStore  
  class InvalidClientUserIdError < RuntimeError; end
  class InvalidClientAppIdError < RuntimeError; end
  class InvalidSourceNameError < RuntimeError; end
  
  class Client < Model
    field :device_type,:string
    field :user_id,:string
    field :app_id,:string
    attr_accessor :source_name
    
    include Document
    
    def self.create(fields={})
      raise InvalidClientUserIdError.new('Invalid User Id Argument') unless fields[:user_id]
      raise InvalidClientAppIdError.new('Invalid App Id Argument') unless fields[:app_id]
      super(fields) 
    end
    
    def self.load(key,source_name)
      c = Client.with_key(key)
      c.source_name = source_name
      c
    end
    
    def doc_suffix(doctype)
      doctype = doctype.to_s
      if self.source_name
        "#{self.id}:#{self.source_name}:#{doctype}"
      elsif doctype == '*'
        "#{self.id}:*"
      else
        raise InvalidSourceNameError.new('Invalid Source Name For Client')   
      end          
    end
    
    def delete
      flash_data('*')
      super
    end
  end
end