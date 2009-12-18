require 'uuidtools'
module RhosyncStore
  class ApiToken < Model
    field :value,:string
    field :user_id,:string
    
    def self.create(fields)
      fields[:value] = UUIDTools::UUID.random_create.to_s.gsub(/\-/,'')
      fields[:id] = fields[:value]
      object = super(fields)
    end
    
    def user
      User.with_key(self.user_id)
    end
  end
end
    