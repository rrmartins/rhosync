module RhosyncStore
  class App < Model
    field :name, :string
    set   :users, :string
    set   :sources, :string
    attr_reader :store
    
    def self.create(fields={})
      fields[:id] = fields[:name]
      super(fields)
    end
    
    def delete
      sources.members.each do |source_name|
        Source.with_key(source_name).delete
      end
      users.members.each do |user_name|
        User.with_key(user_name).delete
      end
      super
    end
      
    # Returns the data-store for an App
    def store
      @store.nil? ? @store = Store.new : @store
    end
  end
end