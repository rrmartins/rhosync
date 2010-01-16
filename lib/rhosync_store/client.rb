module RhosyncStore  
  class InvalidSourceNameError < RuntimeError; end
  
  class Client < Model
    field :device_type,:string
    field :user_id,:string
    field :app_id,:string
    attr_accessor :source_name
    validates_presence_of :app_id, :user_id
    
    include Document
    
    def self.create(fields,params={})
      fields[:id] = get_random_uuid
      super(fields,params) 
    end
    
    def self.load(id,params)
      validate_attributes(params)
      super(id,params)
    end
    
    def doc_suffix(doctype)
      doctype = doctype.to_s
      if doctype == '*'
        "#{self.user_id}:#{self.id}:*"
      elsif self.source_name 
        "#{self.user_id}:#{self.id}:#{self.source_name}:#{doctype}"
      else
        raise InvalidSourceNameError.new('Invalid Source Name For Client')   
      end          
    end
    
    def delete
      flash_data('*')
      super
    end
    
    private
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute source_name') unless params[:source_name]
    end
  end
end