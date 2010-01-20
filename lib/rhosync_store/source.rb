module RhosyncStore
  class Source < Model
    field :source_id,:integer
    field :name,:string
    field :url,:string
    field :login,:string
    field :password,:string
    field :priority,:integer
    field :callback_url,:string
    field :partition_type,:string
    field :sync_type,:string
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
      fields[:partition_type] ||= :user
      fields[:sync_type] ||= :incremental
      super(fields,params)
    end
    
    def self.load(id,params)
      validate_attributes(params)
      super(id,params)
    end
    
    def clone(src_doctype,dst_doctype)
      Store.clone(docname(src_doctype),docname(dst_doctype))
    end
    
    # Return the user associated with a source
    def user
      @user ||= User.load(self.user_id)
    end
    
    # Return the app the source belongs to
    def app
      @app ||= App.load(self.app_id)
    end
    
    def get_read_state
      id = {:app_id => self.app_id,:user_id => user_by_partition,
        :source_name => self.name}
      @read_state ||= ReadState.load(id)
      @read_state ||= ReadState.create(id)   
    end
    
    def doc_suffix(doctype)
      "#{user_by_partition}:#{self.name}:#{doctype.to_s}"
    end
    
    def delete
      flash_data('*')
      super
    end
    
    def partition
      self.partition_type.to_sym
    end
    
    def partition=(value)
      self.partition_type = value
    end
    
    def user_by_partition
      self.partition.to_sym == :user ? self.user_id : '__shared__'
    end
  
    def check_refresh_time
      self.get_read_state.poll_interval == 0 or 
      (self.get_read_state.poll_interval != -1 and self.get_read_state.refresh_time <= Time.now.to_i)
    end
        
    def if_need_refresh(client_id=nil,params=nil)
      if check_refresh_time
        yield client_id,params
        self.get_read_state.refresh_time = Time.now.to_i + self.get_read_state.poll_interval
      end
    end
    
    private
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute user_id') unless params[:user_id]
      raise ArgumentError.new('Missing required attribute app_id') unless params[:app_id]
    end
  end
end