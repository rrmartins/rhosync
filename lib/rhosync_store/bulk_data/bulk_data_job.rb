require 'sqlite3'

module RhosyncStore
  module BulkDataJob
    @queue = :bulk_data
    
    def self.perform(params)
      bulk_data = BulkData.with_key(params[:data_name]) if BulkData.is_exist?(params[:data_name],'name')
      if bulk_data
        create_sqlite_data_file(bulk_data)
        create_hsql_data_file(bulk_data)
        bulk_data.state = :completed
      end
    end
    
    def self.import_data_to_db(db,source_name,data)
      db.transaction do |database|
        database.prepare("insert into object_values 
          (source_id,attrib,object,value) values (?,?,?,?)") do |stmt|
          data.each do |object_id,object|
            object.each do |attrib,value|
              stmt.execute(source_name,attrib,object_id,value)
            end
          end
        end
      end
    end
    
    def self.create_sqlite_data_file(bulk_data)
      schema,index,dbfile = get_file_args(bulk_data.name)
      File.delete(dbfile) if File.exists?(dbfile)
      FileUtils.mkdir_p(File.dirname(dbfile))
      db = SQLite3::Database.new(dbfile)
      db.execute(File.open(schema,'r').read)
      bulk_data.sources.members.each do |source_name|
        data = Source.with_key(source_name).get_data(:md)
        import_data_to_db(db,source_name,data)
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
      dbfile = File.join(RhosyncStore.data_directory,bulk_data_name)
      [schema,index,dbfile]
    end
  end
end