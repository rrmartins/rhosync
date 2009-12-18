module RhosyncStore
  class App < Model
    field :name, :string
    set   :users, :string
    set   :sources, :string
    attr_reader :store,:delegate
    
    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        begin
          require underscore(fields[:name])
          @delegate = fields[:name].constantize
        rescue Exception; end
        super(fields)
      end
    
      def appdir(name)
        File.join(RhosyncStore.app_directory,name)
      end
    end
    
    def can_authenticate?
      @delegate && @delegate.singleton_methods.include?("authenticate")
    end

    def authenticate(login, password, session)
      if @delegate && @delegate.authenticate(login, password, session)
        user = User.with_key(login)
        if not user
          user = User.create(:login => login)
          self.users << user
        end
        return user
      end
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