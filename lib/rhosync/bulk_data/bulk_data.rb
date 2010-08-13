require 'resque'
require 'rhosync/jobs/bulk_data_job'

module Rhosync
  class BulkData < Model
    field :name, :string
    field :state, :string
    field :app_id, :string
    field :user_id, :string
    field :refresh_time, :integer
    field :dbfile,:string
    set   :sources, :string
    validates_presence_of :app_id, :user_id, :sources
    
    def completed?
      if state.to_sym == :completed
        return true
      end
      false
    end
    
    def delete
      sources.members.each do |source|
        s = Source.load(source,{:app_id => app_id, :user_id => user_id})
        Store.flash_data(s.docname(:md_copy)) if s
      end
      super
    end
    
    def process_sources
      sources.members.each do |source|
        s = Source.load(source,{:app_id => app_id, :user_id => user_id})
        if s
          SourceSync.new(s).process_query(nil)
          s.clone(:md,:md_copy) unless s.sync_type.to_sym == :bulk_sync_only
        end
      end
    end
    
    def url
      zippath = dbfile.gsub(Regexp.compile(Regexp.escape(Rhosync.data_directory)), "")
      File.join('/data',zippath)
    end
    
    def dbfiles_exist?
      files = [dbfile,dbfile+'.rzip']
      if Rhosync.blackberry_bulk_sync
        files << dbfile+'.hsqldb.data'
        files << dbfile+'.hsqldb.script'
        files << dbfile+'.hsqldb.properties'
      end
      files.each do |file|
        return false unless File.exist?(file)
      end
      true
    end
    
    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        fields[:state] ||= :inprogress
        fields[:sources] ||= []
        super(fields)
      end
      
      def enqueue(params={})
        Resque.enqueue(BulkDataJob,params)
      end
      
      def get_name(partition,user_id)
        if partition == :user
          File.join(APP_NAME,user_id,user_id)
        else
          File.join(APP_NAME,APP_NAME)
        end
      end
      
      def schema_file
        File.join(File.dirname(__FILE__),'syncdb.schema')
      end
      
      def index_file
        File.join(File.dirname(__FILE__),'syncdb.index.schema')
      end
    end
  end
end

