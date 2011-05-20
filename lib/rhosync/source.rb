module Rhosync
  class Source < Model
    field :test_id,:string # FIXME: dummy field
#    attr_accessor :rho__id
            
    [:name, :url, :login, :password, :callback_url, :partition_type, :sync_type, 
      :queue, :query_queue, :cud_queue, :belongs_to, :has_many].each do |attrib|
      define_method("#{attrib}=") do |value|
        return source_set(attrib, value) if source_exist?
        instance_variable_set(:"@#{attrib}", value)
      end
      define_method("#{attrib}") do
        return source_get(attrib)  if source_exist?
        instance_variable_get(:"@#{attrib}")
      end
    end

    [:source_id, :priority, :poll_interval].each do |attrib|
      define_method("#{attrib}=") do |value|
        value = (value.nil?) ? nil : value.to_i 
        return source_set(attrib, value) if source_exist?
        instance_variable_set(:"@#{attrib}", value)
      end
      define_method("#{attrib}") do
        return source_get(attrib)  if source_exist?
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
#      log "create - 1: #{fields.inspect}, #{params.inspect}"
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      fields[:id] = fields[:name]
      set_defaults(fields)
      obj = super(fields,params)  # FIXME:      
#      log "create - 2: #{obj.inspect}"
      s_data = {}
      fields.each do |name,value|
        s_data[name.to_sym] = value if obj.respond_to?(name)
      end
      @@source_data[obj.rho__id.to_sym] = s_data
#      puts "create - 3: #{obj.inspect}"
#      puts "create - 4: #{@@source_data[obj.rho__id.to_sym].inspect}"
      obj
    end
    
    def self.load(id,params)
#      log "load - 1: #{id}, #{params.inspect}" # FIXME:
      validate_attributes(params)
      obj = super(id,params)
#      log "load - 2: #{id}, #{obj.inspect}" # FIXME:
#      log "load - 3: #{@@source_data.inspect}" unless obj # FIXME:
#      if obj.nil? && @@source_data[id.to_sym]
##        log "load - 3-1: #{@@source_data[id.to_sym].inspect}" # FIXME:
##        obj = self.new
##        log "load - 3-2: #{obj.inspect}" # FIXME:
#      end
      if obj 
        obj.rho__id = id unless obj.rho__id # FIXME
#        log "load - 4: #{obj.rho__id}" # FIXME
        if @@source_data[obj.rho__id.to_sym]
          @@source_data[obj.rho__id.to_sym].each do |k,v|
#            log "--- #{k.to_sym} => #{v.to_s}"
#            obj.instance_variable_set(:"@#{k}", v.to_s)
            obj.send "#{k.to_s}=".to_sym, v.to_s          
          end
#          log "load - 5: #{obj.inspect}" # FIXME:
#          puts "load - 5: #{obj.inspect}" # FIXME:
#          puts "load - 6: #{@@source_data[obj.rho__id.to_sym].inspect}" # FIXME:
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
      flash_data('*')
      super
      @@source_data[rho__id.to_sym] = nil if  source_exist?
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
    
    @@source_data = {}
    
    def source_exist?
      @@source_data[rho__id.to_sym];
    end  

    def source_get(attr_name)
      @@source_data[rho__id.to_sym][attr_name.to_sym]
    end
    
    def source_set(attr_name, value)
      @@source_data[rho__id.to_sym][attr_name.to_sym] = value
    end

  end
end