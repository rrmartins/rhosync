require 'sqlite3'

module RhosyncStore
  module SqliteData
    @queue = :bulk_data
    
    def self.perform(params)
      bulk_data = BulkData.with_key(params[:data_name]) if BulkData.is_exist?(params[:data_name],'name')
      if bulk_data
        schema = File.open(File.join(File.dirname(__FILE__),'syncdb.schema'),'r').read
        index = File.open(File.join(File.dirname(__FILE__),'syncdb.index.schema'),'r').read
        dbfile = File.join(RhosyncStore.data_directory,bulk_data.name)
        File.delete(dbfile) if File.exists?(dbfile)
        FileUtils.mkdir_p(File.dirname(dbfile))
        db = SQLite3::Database.new(dbfile)
        db.execute(schema)
        bulk_data.sources.members.each do |source_name|
          data = Source.with_key(source_name).get_data(:md)
          import_data_to_db(db,source_name,data)
        end
        db.execute(index)
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
  end
end