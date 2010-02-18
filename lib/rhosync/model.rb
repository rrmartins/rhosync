module Rhosync
  # Taken from http://github.com/voloko/redis-model
  #
  # Simple models for redis-rb.
  
  class Model
    attr_accessor :id
  
    def initialize(id=nil)
      self.id = id
    end
  
    def redis #:nodoc:
      self.class.redis
    end
  
    # Issues delete commands for all defined fields
    def delete(name = nil)
      if name
        redis.delete field_key(name.to_s)
      else
        self.class.fields.each do |field|
          redis.delete field_key(field[:name])
        end
      end
    end
  
    def field_key(name) #:nodoc:
      self.class._field_key(prefix,id,name)
    end

    # Increment the specified integer field by 1 or the
    # specified amount.
    def increment!(name,amount=1)
      raise ArgumentError, "Only integer fields can be incremented." unless self.class.fields.include?({:name => name.to_s, :type => :integer})
      redis.incr(field_key(name), amount)
    end
  
    # Decrement the specified integer field by 1 or the
    # specified amount.
    def decrement!(name,amount=1)
      raise ArgumentError, "Only integer fields can be decremented." unless self.class.fields.include?({:name => name.to_s, :type => :integer})
      redis.decr(field_key(name), amount)
    end
    
    def next_id #:nodoc:
      redis.incr "sequence:#{self.prefix}:id"
    end
  
    def self.is_exist?(id)
      !redis.get(self._field_key(self._prefix,id,'rho__id')).nil?
    end
    
  protected
    def prefix #:nodoc:
      @prefix ||= self.class.prefix || self.class.class_prefix(self.class)
    end
 
    class << self
      # Defaults to model_name.dasherize
      attr_accessor :prefix
      attr_accessor :validates_presence
      
      def _prefix
        class_prefix(self)
      end
  
      def _field_key(p,i,n) #:nodoc:
        "#{p}:#{i}:#{n}"
      end

      def class_prefix(classname)
        classname.to_s.
          sub(%r{(.*::)}, '').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          downcase
      end
  
      # Creates new model instance with new uniqid
      # NOTE: "sequence:model_name:id" key is used
      def create(params = {}, attributes = {})
        raise ArgumentError.new("Record already exists for '#{params[:id]}'") if self.is_exist?(params[:id])
        if self.validates_presence
          self.validates_presence.each do |field|
            raise ArgumentError.new("Missing required field '#{field}'") unless params[field]
          end
        end
        o = self.new
        o.id = params[:id].nil? ? o.next_id : params[:id]
        params[:rho__id] = params[:id]
        populate_model(o,params)
        populate_attributes(o,attributes)
      end
      
      def load(id, params={})
        return unless self.is_exist?(id)
        populate_attributes(self.with_key(id),params)
      end
      
      def populate_attributes(obj,attribs)
        attribs.each do |attrib,value|
          obj.send "#{attrib.to_s}=".to_sym, value
        end
        obj
      end
      
      def validates_presence_of(*names)
        self.validates_presence ||= []
        names.each do |name|
          self.validates_presence << name
        end
      end
  
      # Creates new model instance with given id
      alias_method :with_key, :new
      alias_method :with_next_key, :create
  
      # Defines marshaled rw accessor for redis string value
      def field(name, type = :string)
        if @fields.nil?
          @fields = []
          field :rho__id, :string
        end        
        type = type.to_sym
        type = :integer if type == :int
      
        class_name = marshal_class_name(name, type)
      
        fields << {:name => name.to_s, :type => type}
        if type == :string
          class_eval "def #{name}; @#{name} ||= redis[field_key('#{name}')]; end"
          class_eval "def #{name}=(value); @#{name} = redis[field_key('#{name}')] = value; end"
        else
          class_eval "def #{name}; @#{name} ||= Marshal::#{class_name}.load(redis[field_key('#{name}')]); end"
          class_eval "def #{name}=(value); @#{name} = value; redis[field_key('#{name}')] = Marshal::#{class_name}.dump(value); end"
        end
      end
      alias_method :value, :field
        
      # Defines accessor for redis list
      def list(name, type = :string)
        class_name = marshal_class_name(name, type)
      
        fields << {:name => name.to_s, :type => :list}
        class_eval "def #{name}; @#{name} ||= ListProxy.new(self.redis, field_key('#{name}'), Marshal::#{class_name}); end"
        eval_writer(name)
      end
  
      # Defines accessor for redis set
      def set(name, type = :string)
        class_name = marshal_class_name(name, type)
      
        fields << {:name => name.to_s, :type => :set}
        class_eval "def #{name}; @#{name} ||= SetProxy.new(self.redis, field_key('#{name}'), Marshal::#{class_name}); end"
        eval_writer(name)
      end
    
      def marshal_class_name(name, type)
        Marshal::TYPES[type] or raise ArgumentError.new("Unknown type #{type} for field #{name}")
      end
  
      # Redefine this to change connection options
      def redis
        @@redis ||= Store.db
      end
    
      def fields #:nodoc:
        @fields ||= []
      end
 
    protected
      def eval_writer(name) #:nodoc:
        class_eval <<-END
  def #{name}=(value)
  field = self.#{name};
  if value.respond_to?(:each)
  value.each {|v| field << v}
  else
  field << v
  end
  end
  END
      end
  
      def populate_model(model, fields)
        return model if fields.empty?
        methods = model.methods
        fields.each do |name,value|
          model.send("#{name}=", value) if methods.include?(name.to_s)
        end
        model
      end
    end
  
    module Marshal
      TYPES = {
        :string => 'String',
        :integer => 'Integer',
        :float => 'Float',
        :datetime => 'DateTime',
        :json => 'JSON',
      }
 
      class String
        def self.dump(v)
          v
        end
 
        def self.load(v)
          v
        end
      end
 
      class Integer
        def self.dump(v)
          v.to_s
        end
 
        def self.load(v)
          v && v.to_i
        end
      end
 
      class Float
        def self.dump(v)
          v.to_s
        end
 
        def self.load(v)
          v && v.to_f
        end
      end
 
      class DateTime
        def self.dump(v)
          v.strftime('%FT%T%z')
        end
 
        def self.load(v)
          v && ::DateTime.strptime(v, '%FT%T%z')
        end
      end
 
      class JSON
        def self.dump(v)
          ::JSON.dump(v)
        end
 
        def self.load(v)
          v && ::JSON.load(v)
        end
      end
    end
  
  
  
    class FieldProxy #:nodoc
      def initialize(redis, name, marshal)
        @redis = redis
        @name = name
        @marshal = marshal
      end
 
      # def method_missing(method, *argv)
      #   translated_method = translate_method_name(method)
      #   raise NoMethodError.new("Method '#{method}' is not defined") unless translated_method
      #   @redis.send translated_method, @name, *argv
      # end
      #  
      # protected
      #   def translate_method_name(m)
      #     m
      #   end
    end
 
 
 
    class ListProxy < FieldProxy #:nodoc:
      def <<(v)
        @redis.rpush @name, @marshal.dump(v)
      end
      alias_method :push_tail, :<<
    
      def push_head(v)
        @redis.lpush @name, @marshal.dump(v)
      end
    
      def pop_tail
        @marshal.load(@redis.rpop(@name))
      end
    
      def pop_head
        @marshal.load(@redis.lpop(@name))
      end
    
      def [](from, to = nil)
        if to.nil?
          @marshal.load(@redis.lindex(@name, from))
        else
          @redis.lrange(@name, from, to).map! { |v| @marshal.load(v) }
        end
      end
      alias_method :range, :[]
    
      def []=(index, v)
        @redis.lset(@name, index, @marshal.dump(v))
      end
      alias_method :set, :[]=
    
      def include?(v)
        @redis.exists(@name, @marshal.dump(v))
      end
    
      def remove(count, v)
        @redis.lrem(@name, count, @marshal.dump(v))
      end
    
      # def length
      #   @redis.llen(@name)
      # end
      #     
      # def trim(from, to)
      #   @redis.ltrim(@name, from, to)
      # end
      #     
      # def to_s
      #   range(0, 100).join(', ')
      # end
      #  
    # protected
    #   def translate_method_name(m)
    #     COMMANDS[m]
    #   end
    end
 
 
 
    class SetProxy < FieldProxy #:nodoc:
      # COMMANDS = {
      #   :intersect_store => "sinterstore",
      #   :union_store => "sunionstore",
      #   :diff_store => "sdiffstore",
      #   :move => "smove",
      # }
    
      def <<(v)
        @redis.sadd @name, @marshal.dump(v)
      end
      alias_method :add, :<<
    
      def delete(v)
        @redis.srem @name, @marshal.dump(v)
      end
      alias_method :remove, :delete
    
      def include?(v)
        @redis.sismember @name, @marshal.dump(v)
      end
      alias_method :has_key?, :include?
      alias_method :member?, :include?
    
      def members
        @redis.smembers(@name).map { |v| @marshal.load(v) }
      end
    
      def intersect(*keys)
        @redis.sinter(@name, *keys).map { |v| @marshal.load(v) }
      end
    
      def union(*keys)
        @redis.sunion(@name, *keys).map { |v| @marshal.load(v) }
      end
    
      def diff(*keys)
        @redis.sdiff(@name, *keys).map { |v| @marshal.load(v) }
      end
    
        # def length
        #   @redis.llen(@name)
        # end
        #     
        # def to_s
        #   members.join(', ')
        # end
        #  
    # protected
    #   def translate_method_name(m)
    #     COMMANDS[m]
    #   end
    end
  end
end