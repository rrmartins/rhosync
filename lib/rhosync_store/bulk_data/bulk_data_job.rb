require 'sqlite3'
$:.unshift File.join(File.dirname(__FILE__),'..','..','..','lib')
require 'rhosync_store'

module RhosyncStore
  
  module BulkDataJob
    @queue = :bulk_data
    
    def self.perform(params)
      RhosyncStore.bootstrap(File.join(File.dirname(__FILE__),'..','..','..','apps'),
        File.join(File.dirname(__FILE__),'..','..','..','data'))
      bulk_data = BulkData.load(params[:data_name]) if BulkData.is_exist?(params[:data_name])
      if bulk_data
        bulk_data.process_sources
        create_sqlite_data_file(bulk_data)
        create_hsql_data_file(bulk_data)
        bulk_data.state = :completed
      end
    end
    
    def self.import_data_to_db(db,source)
      data = source.get_data(:md)
      db.transaction do |database|
        database.prepare("insert into object_values 
          (source_id,attrib,object,value) values (?,?,?,?)") do |stmt|
          data.each do |object_id,object|
            object.each do |attrib,value|
              stmt.execute(source.source_id.to_i,attrib,object_id,value)
            end
          end
        end
      end
    end
    
    def self.create_sqlite_data_file(bulk_data)
      schema,index,bulk_data.dbfile = get_file_args(bulk_data.name)
      FileUtils.mkdir_p(File.dirname(bulk_data.dbfile))
      db = SQLite3::Database.new(bulk_data.dbfile)
      db.execute(File.open(schema,'r').read)
      bulk_data.sources.members.each do |source_name|
        source = Source.load(source_name,{:app_id => bulk_data.app_id,
          :user_id => bulk_data.user_id})
        import_data_to_db(db,source)
      end
      db.execute(File.open(index,'r').read)
    end
    
    def self.create_hsql_data_file(bulk_data)
      schema,index,dbfile = get_file_args(bulk_data.name)
      hsql_file = dbfile + ".hsqldb"
      system('java','-cp',
        File.join(File.dirname(__FILE__),'..','..','..','vendor','hsqldata.jar'),
        'com.rhomobile.hsqldata.HsqlData',
        dbfile, hsql_file, schema, index)
    end
    
    def self.get_file_args(bulk_data_name)
      schema = File.join(File.dirname(__FILE__),'syncdb.schema')
      index = File.join(File.dirname(__FILE__),'syncdb.index.schema')
      dbfile = File.join(RhosyncStore.data_directory,bulk_data_name+'_'+Time.now.to_i.to_s+'.data')
      [schema,index,dbfile]
    end
  end
end