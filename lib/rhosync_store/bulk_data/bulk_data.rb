require 'resque'
$:.unshift File.join(File.dirname(__FILE__))
require 'bulk_data_job'

module RhosyncStore
  class BulkData < Model
    field :name, :string
    field :state, :string
    field :app_id, :string
    field :user_id, :string
    set   :sources, :string
    validates_presence_of :app_id, :user_id, :sources
    
    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        fields[:state] ||= ''
        fields[:sources] ||= []
        super(fields)
      end
    
      def exists?(params)
        data_name = params[:name]
        if BulkData.is_exist?(data_name)
          data = BulkData.load(data_name)
          if data.state.to_sym == :completed and
            File.exist?(File.join(RhosyncStore.data_directory,data_name)) and
            params[:sources].sort == data.sources.members.sort
            return true
          end 
        end
        false
      end
      
      def enqueue(params={})
        Resque.enqueue(BulkDataJob,params)
      end
    end
  end
end

