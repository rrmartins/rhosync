module RhosyncStore
  class Source < Model
    field :name,:string
    field :url,:string
    field :login,:string
    field :password,:string
    field :poll_interval,:integer
    field :refresh_time,:integer
    field :priority,:integer
    field :callback_url,:string
    field :user_id,:string
    field :app_id,:string
    attr_reader :document
    
    def self.create(fields={})
      fields[:name] ||= self.class.name
      fields[:id] = fields[:name]
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:priority] ||= 3
      fields[:poll_interval] ||= 300
      fields[:refresh_time] ||= Time.now.to_i
      super(fields)
    end
    
    # Return the user associated with a source
    def user
      User.with_key(self.user_id)
    end
    
    # Return the app the source belongs to
    def app
      App.with_key(self.app_id)
    end
    
    def document
      @document.nil? ? @document = Document.new('md',self.app_id,self.user_id,'0',self.name) : @document
    end
    
    def delete
       self.app.store.flash_data(Document.new('md*',self.app_id,self.user_id,0,'*').get_key)
      super
    end
  end
end