module Rhosync
  class Source < Model
    field :test_id,:string # FIXME: dummy field
    @@source_data = {}
    
    [:name, :url, :login, :password, :callback_url, :partition_type, :sync_type, 
      :queue, :query_queue, :cud_queue, :belongs_to, :has_many].each do |attrib|
      define_method("#{attrib}=") do |value|
        return @@source_data[id.to_sym][attrib.to_sym] = value if @@source_data[id.to_sym]
        instance_variable_set(:"@#{attrib}", value)
      end
      define_method("#{attrib}") do
        return @@source_data[id.to_sym][attrib.to_sym] if @@source_data[id.to_sym]
        instance_variable_get(:"@#{attrib}")
      end
    end

    [:source_id, :priority, :poll_interval].each do |attrib|
       define_method("#{attrib}=") do |value|
         return @@source_data[id.to_sym][attrib.to_sym] = value.to_i if id && @@source_data[id.to_sym]
         instance_variable_set(:"@#{attrib}", value.to_i)
       end
      define_method("#{attrib}") do
        return @@source_data[id.to_sym][attrib.to_sym] if id && @@source_data[id.to_sym]
        instance_variable_get(:"@#{attrib}")
      end
     end
          
    attr_accessor :app_id, :user_id
    validates_presence_of :name #, :source_id
    
    include Document
    include LockOps
  
    def self.set_defaults(fields)
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:priority] ||= 3
      fields[:partition_type] ||= :user
      fields[:poll_interval] ||= 300
      fields[:sync_type] ||= :incremental
      fields[:belongs_to] = fields[:belongs_to].to_json if fields[:belongs_to]
      fields[:schema] = fields[:schema].to_json if fields[:schema]
    end
        
    def self.create(fields,params)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      fields[:id] = fields[:name]
      set_defaults(fields)
      obj = super(fields,params)  # FIXME:      
      h = {}
      fields.each do |name,value|
        if obj.respond_to?(name)
          h[name.to_sym] = value  
        end
      end
      @@source_data[obj.id.to_sym] = h
      obj      
    end
    
    def self.load(id,params)
      validate_attributes(params)
      obj = super(id,params)
      if obj
        if @@source_data[obj.id.to_sym]
          @@source_data[obj.id.to_sym].each do |k,v|
            obj.send "#{k.to_s}=".to_sym, v.to_s          
          end
        end  
      end
      obj
    end
    
    def self.update_associations(sources)
      params = {:app_id => APP_NAME,:user_id => '*'}
      sources.each { |source| Source.load(source, params).has_many = nil }
      sources.each do |source|
        s = Source.load(source, params)
        if s.belongs_to
          belongs_to = JSON.parse(s.belongs_to)
          if belongs_to.is_a?(Array)
            belongs_to.each do |entry|
              attrib = entry.keys[0]
              model = entry[attrib]
              owner = Source.load(model, params)
              owner.has_many ||= ''
              owner.has_many = owner.has_many+',' if owner.has_many.length > 0
              owner.has_many += [source,attrib].join(',')
            end
          else
            log "WARNING: Incorrect belongs_to format for #{source}, belongs_to should be an array."
          end
        end
      end
    end
    
    def blob_attribs
      return '' unless self.schema
      schema = JSON.parse(self.schema)
      blob_attribs = []
      schema['property'].each do |key,value|
        values = value ? value.split(',') : []
        blob_attribs << key if values.include?('blob')
      end
      blob_attribs.sort.join(',')
    end
    
    def update(fields)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      self.class.set_defaults(fields)
      super(fields)
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
    
    def schema
      @schema ||= self.get_value(:schema)
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
      ref_to_data = id.to_sym
      flash_data('*')
      super
      @@source_data[ref_to_data] = nil if ref_to_data
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