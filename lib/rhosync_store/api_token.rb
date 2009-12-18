require 'uuidtools'
module RhosyncStore
  class ApiToken < Model
    field :value,:string
    field :user_id,:string
    
    def self.create(fields)
      fields[:value] = UUIDTools::UUID.random_create.to_s.gsub(/\-/,'')
      super(fields)
    end
  end
end
    