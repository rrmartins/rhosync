module Rhosync  
  class InvalidSourceNameError < RuntimeError; end
  
  class Client < Model
    field :device_type,:string
    field :device_pin,:string
    field :device_port,:string
    
    field :user_id,:string
    field :app_id,:string
    attr_accessor :source_name
    validates_presence_of :app_id, :user_id
    
    include Document
    include LockOps
    
    def self.create(fields,params={})
      Rhosync.license.check_and_use_seat
      fields[:id] = get_random_uuid
      res = super(fields,params)
      user = User.load(fields[:user_id])
      user.clients << res.id
      if Rhosync.stats
        Rhosync::Stats::Record.set('clients') { Store.incr('client:count') }
      else
        Store.incr('client:count')
      end
      res
    end
    
    def self.load(id,params)
      validate_attributes(params)
      super(id,params)
    end
    
    def app
      @app ||= App.load(app_id)
    end
    
    def doc_suffix(doctype)
      doctype = doctype.to_s
      if doctype == '*'
        "#{self.user_id}:#{self.id}:*"
      elsif self.source_name 
        "#{self.user_id}:#{self.id}:#{self.source_name}:#{doctype}"
      else
        raise InvalidSourceNameError.new('Invalid Source Name For Client')   
      end          
    end
    
    def delete
      flash_data('*')
      Rhosync.license.free_seat
      if Rhosync.stats
        Rhosync::Stats::Record.set('clients') { Store.decr('client:count') }
      else
        Store.decr('client:count')
      end
      super
    end
    
    def switch_user(new_user_id)
      flash_data('*')
      User.load(self.user_id).clients.delete(self.id)
      User.load(new_user_id).clients << self.id
      self.user_id = new_user_id
    end
    
    def update_clientdoc(sources)
      # TODO: We need to store schema info and data info in bulk data
      # source masterdoc and source schema might have changed!
      sources.each do |source|
        s = Source.load(source,{:app_id => app_id,:user_id => user_id})
        unless s.sync_type.to_sym == :bulk_sync_only
          self.source_name = source
          Store.clone(s.docname(:md_copy),self.docname(:cd))
        end
        self.put_value(:schema_sha1,s.get_value(:schema_sha1))
      end
    end
    
    def update_fields(params)
      [:device_type,:device_pin,:device_port].each do |setting|
        self.send "#{setting}=".to_sym, params[setting].to_s if params[setting]
      end
    end
    
    private
    
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute source_name') unless params[:source_name]
    end
  end
end