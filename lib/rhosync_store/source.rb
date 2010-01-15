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
    attr_accessor :app_id, :user_id
    validates_presence_of :name
    
    include Document
    
    def self.create(fields,params)
      validate_attributes(params)
      fields[:id] = fields[:name]
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:priority] ||= 3
      fields[:poll_interval] ||= 300
      fields[:refresh_time] ||= Time.now.to_i
      super(fields,params)
    end
    
    def self.load(id,params)
      validate_attributes(params)
      super(id,params)
    end
    
    # Return the user associated with a source
    def user
      @user ||= User.load(self.user_id)
    end
    
    # Return the app the source belongs to
    def app
      @app ||= App.load(self.app_id)
    end
    
    def doc_suffix(doctype)
      "#{self.name}:#{doctype.to_s}"
    end
    
    def delete
      flash_data('*')
      super
    end
    
    private
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute user_id') unless params[:user_id]
      raise ArgumentError.new('Missing required attribute app_id') unless params[:app_id]
    end
  end
end