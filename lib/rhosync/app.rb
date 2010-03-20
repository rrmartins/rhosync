module Rhosync
  class App < Model
    field :name, :string
    set   :users, :string
    set   :sources, :string
    attr_reader :delegate
    validates_presence_of :name
    
    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        begin
          require underscore(fields[:name])
        rescue Exception; end
        super(fields)
      end
    end
    
    def can_authenticate?
      self.delegate && self.delegate.singleton_methods.include?("authenticate")
    end

    def authenticate(login, password, session)
      if self.delegate && self.delegate.authenticate(login, password, session)
        user = User.load(login) if User.is_exist?(login)
        if not user
          user = User.create(:login => login)
          users << user.id
        end
        return user
      end
    end
    
    def delete
      sources.members.each do |source_name|
        Source.load(source_name,{:app_id => self.name,
          :user_id => '*'}).delete
      end
      users.members.each do |user_name|
        User.load(user_name).delete
      end
      ReadState.delete(self.name)
      super
    end
    
    def delegate
      @delegate.nil? ? Object.const_get(camelize(self.name)) : @delegate
    end
    
    def partition_sources(partition,user_id)
      names = []
      need_refresh = false
      sources.members.each do |source|
        s = Source.load(source,{:app_id => self.name,
          :user_id => user_id})
        if s.partition == partition
          names << s.name
          need_refresh = true if !need_refresh and s.check_refresh_time  
        end
      end
      {:names => names,:need_refresh => need_refresh}
    end
  end
end