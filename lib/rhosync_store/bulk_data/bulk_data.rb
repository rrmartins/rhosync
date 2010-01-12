require 'resque'
$:.unshift File.join(File.dirname(__FILE__))
require 'sqlite_data'
require 'hsql_data'

module RhosyncStore
  class UnsupportedDbType < RuntimeError; end
  
  class BulkData < Model
    field :name, :string
    field :state, :string
    set   :sources, :string
    
    class << self
      def create(fields={})
         fields[:id] = fields[:name]
         fields[:state] ||= ''
         fields[:sources] ||= []
         
         super(fields)
       end
    
      def exists?(params)
        data_name = docname(params[:client_id])
        if BulkData.is_exist?(data_name,'name')
          data = BulkData.with_key(data_name)
          if data.state.to_sym == :completed and
            File.exist?(File.join(RhosyncStore.data_directory,data_name)) and
            params[:sources].sort == data.sources.members.sort
            return true
          end 
        end
        false
      end
      
      def enqueue(params)
        case params[:dbtype]
        when :sqlite then Resque.enqueue(SqliteData,params)
        when :hsql then Resque.enqueue(HsqlData,params)
        else raise UnsupportedDbType.new('Unsupported DB Type')
        end
      end
    
      def docname(client_id)
        c = Client.with_key(client_id)
        File.join(c.app_id,c.user_id,c.id.to_s+'.data')
      end
    end
    
  end
end

