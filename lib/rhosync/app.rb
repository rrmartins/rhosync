module Rhosync
  class App < Model
    field :name, :string
    set   :users, :string
    attr_reader :delegate
    validates_presence_of :name
    
    @@sources = []
    
    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        begin
          require under_score(fields[:name])
        rescue Exception; end
        super(fields)
      end
    end
    
    def can_authenticate?
      # TODO: optimize it!
      self.delegate && self.delegate.singleton_methods.map(&:to_sym).include?(:authenticate)
    end

    def authenticate(login, password, session)
      if Rhosync.appserver
        auth_result = DynamicAdapter.authenticate(login,password)
      elsif self.delegate
        auth_result = self.delegate.authenticate(login, password, session) 
      end
      
      if auth_result
        login = auth_result if auth_result.is_a? String
        user = User.load(login) if User.is_exist?(login)
        if not user
          user = User.create(:login => login)
          users << user.id
        end
        return user
      end
    end
    
    def delegate
      @delegate.nil? ? Object.const_get(camelize(self.name)) : @delegate
    end
    
    def delete
      @@sources = []
      super
    end
    
    def partition_sources(partition,user_id)
      names = []
      @@sources.each do |source|
        s = Source.load(source,{:app_id => self.name,
          :user_id => user_id})
        if s.partition == partition
          names << s.name
        end
      end
      names
    end
    
    def store_blob(obj,field_name,blob)
      self.delegate.send :store_blob, obj,field_name,blob
    end
        
    def sources
      @@sources.uniq! || @@sources
    end
  end
end