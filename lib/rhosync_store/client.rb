module RhosyncStore  
  class InvalidClientUserIdError < RuntimeError; end
  class InvalidClientAppIdError < RuntimeError; end
  
  class Client < Model
    field :device_type,:string
    field :user_id,:string
    field :app_id,:string
    
    def self.create(fields={})
      raise InvalidClientUserIdError.new('Invalid User Id Argument') unless fields[:user_id]
      raise InvalidClientAppIdError.new('Invalid App Id Argument') unless fields[:app_id]
      super(fields)
    end
    
    def delete
      App.with_key(self.app_id).store.flash_data(Document.new('cd*',self.app_id,self.user_id,self.id,'*').get_key)
      super
    end
  end
end