module Rhosync
  class MemoryModel
    @@model_data = {}
    @@string_fields = []
    @@integer_fields = []
    attr_accessor :id
    
    class << self
      attr_accessor :validates_presence
      
      def create(fields,params)
        if self.validates_presence
          self.validates_presence.each do |field|
            raise ArgumentError.new("Missing required field '#{field}'") unless fields[field]
          end
        end
      end
    
      def define_fields(string_fields = [], integer_fields = [])
        @@string_fields,@@integer_fields = string_fields,integer_fields
        integer_fields.each do |attrib|
          define_method("#{attrib}=") do |value|
            value = (value.nil?) ? nil : value.to_i 
            @@model_data[self.name.to_sym][attrib.to_sym] = value
          end
          define_method("#{attrib}") do
            @@model_data[self.name.to_sym][attrib.to_sym]
          end
        end
        string_fields.each do |attrib|
          define_method("#{attrib}=") do |value|
            attrib = attrib.to_sym
            name = nil
            if attrib == :name
              instance_variable_set(:@name, value)
              name = value
            else  
              name = self.name
            end
            @@model_data[name.to_sym] ||= {} # TODO: shouldn't be nil here
            @@model_data[name.to_sym][attrib] = value
          end
          define_method("#{attrib}") do
            @@model_data[instance_variable_get(:@name).to_sym][attrib.to_sym]
          end
          # we have separate methods for this
          @@integer_fields << :poll_interval unless @@integer_fields.include?(:poll_interval)
        end
      end
        
      def validates_presence_of(*names)
        self.validates_presence ||= []
        names.each do |name|
          self.validates_presence << name
        end
      end
      
      def is_exist?(id)
        !@@model_data[id.to_sym].nil?
      end

      def class_prefix(classname)
        classname.to_s.
          sub(%r{(.*::)}, '').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          downcase
      end
    end
    
    def to_array
      res = []
      @@string_fields.each do |field|
        res << {"name" => field, "value" => send(field.to_sym), "type" => "string"}
      end
      @@integer_fields.each do |field|
        res << {"name" => field, "value" => send(field.to_sym), "type" => "integer"}
      end
      res
    end
  end
  
  class Source < MemoryModel
    attr_accessor :app_id, :user_id
            
    validates_presence_of :name
    
    include Document
    include LockOps
    
    # source fields
    define_fields([:id, :rho__id, :name, :url, :login, :password, :callback_url, :partition_type, :sync_type, 
      :queue, :query_queue, :cud_queue, :belongs_to, :has_many, :pass_through], [:source_id, :priority])
    
    def initialize(fields)
      self.name = fields['name'] || fields[:name]
      fields.each do |name,value|
        arg = "#{name}=".to_sym
        self.send(arg, value) if self.respond_to?(arg)
      end
    end
  
    def self.set_defaults(fields)
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:priority] ||= 3
      fields[:partition_type] = fields[:partition_type] ? fields[:partition_type].to_sym : :user
      fields[:poll_interval] ||= 300
      fields[:sync_type] = fields[:sync_type] ? fields[:sync_type].to_sym : :incremental
      fields[:id] = fields[:name]
      fields[:rho__id] = fields[:name]
      fields[:belongs_to] = fields[:belongs_to].to_json if fields[:belongs_to]
      fields[:schema] = fields[:schema].to_json if fields[:schema]
    end
        
    def self.create(fields,params)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      super(fields,params)
      @@model_data[fields[:name].to_sym] = {}
      set_defaults(fields)
      obj = new(fields)
      obj.assign_args(params)
      obj
    end
          
    def self.load(obj_id,params)
      validate_attributes(params)
      model_hash = @@model_data[obj_id.to_sym]
      obj = new(model_hash) if model_hash
      if obj
        obj = obj.dup
        obj.assign_args(params) 
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
    
    def self.delete_all
      params = {:app_id => APP_NAME,:user_id => '*'}
      @@model_data.each { |k,v| Source.load(k,params).flash_store_data }
      @@model_data = {}
    end

    def assign_args(params)
      self.user_id = params[:user_id]
      self.app_id = params[:app_id]   
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
    end
    
    def clone(src_doctype,dst_doctype)
      Store.clone(docname(src_doctype),docname(dst_doctype))
    end
    
    def poll_interval
      value = Store.get_value(poll_interval_key)
      value ? value.to_i : nil
    end
    
    def poll_interval=(interval)
      Store.put_value(poll_interval_key, interval)
    end
    
    # Return the user associated with a source
    def user
      User.load(self.user_id)
    end
    
    # Return the app the source belongs to
    def app
      App.load(self.app_id)
    end
    
    def schema
      self.get_value(:schema)
    end
    
    def read_state
      id = {:app_id => self.app_id,:user_id => user_by_partition,
        :source_name => self.name}
      ReadState.load(id) || ReadState.create(id)  
    end
    
    def doc_suffix(doctype)
      "#{user_by_partition}:#{self.name}:#{doctype.to_s}"
    end

    def flash_store_data
      flash_data('*')
      flash_data(poll_interval_key)
    end

    def delete
      flash_store_data
      @@model_data.delete(rho__id.to_sym) if rho__id
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
    
    def is_pass_through?
      self.pass_through and self.pass_through == 'true'
    end
          
    private
    def poll_interval_key
      "source:#{self.name}:poll_interval"
    end
    
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute user_id') unless params[:user_id]
      raise ArgumentError.new('Missing required attribute app_id') unless params[:app_id]
    end

  end
end