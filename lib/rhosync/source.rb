module Rhosync
  class Source < Model
    field :source_id,:integer
    field :name,:string
    field :url,:string
    field :login,:string
    field :password,:string
    field :priority,:integer
    field :callback_url,:string
    field :poll_interval,:integer
    field :partition_type,:string
    field :sync_type,:string
    field :queue,:string
    field :query_queue,:string
    field :cud_queue,:string
    attr_accessor :app_id, :user_id
    validates_presence_of :name #, :source_id
    
    include Document
    include LockOps
    
    def self.create(fields,params)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      validate_attributes(params)
      fields[:id] = fields[:name]
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:priority] ||= 3
      fields[:partition_type] ||= :user
      fields[:poll_interval] ||= 300
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
    
    def read_state
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
      self.poll_interval == 0 or 
      (self.poll_interval != -1 and self.read_state.refresh_time <= Time.now.to_i)
    end
        
    def if_need_refresh(client_id=nil,params=nil)
      need_refresh = lock(:md) do |s|
        check = check_refresh_time
        s.read_state.refresh_time = Time.now.to_i + s.poll_interval if check
        check
      end
      yield client_id,params if need_refresh
    end
    
    private
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute user_id') unless params[:user_id]
      raise ArgumentError.new('Missing required attribute app_id') unless params[:app_id]
    end
  end
end