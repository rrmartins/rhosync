require 'sqlite3'
require 'zip/zip'

module Rhosync
  module BulkDataJob
    @queue = :bulk_data
    
    def self.perform(params)
      bulk_data = nil
      begin
        bulk_data = BulkData.load(params["data_name"]) if BulkData.is_exist?(params["data_name"])
        if bulk_data
          timer = start_timer('starting bulk data process')
          bulk_data.process_sources
          timer = lap_timer('process_sources',timer)
          ts = Time.now.to_i.to_s
          create_sqlite_data_file(bulk_data,ts)
          timer = lap_timer('create_sqlite_data_file',timer)
          create_hsql_data_file(bulk_data,ts) if Rhosync.blackberry_bulk_sync
          lap_timer('create_hsql_data_file',timer)
          log "finished bulk data process"
          bulk_data.state = :completed
          bulk_data.refresh_time = Time.now.to_i + Rhosync.bulk_sync_poll_interval
        else
          raise Exception.new("No bulk data found for #{params["data_name"]}")
        end
      rescue Exception => e
        bulk_data.delete if bulk_data
        raise e
      end
    end
    
    def self.import_data_to_object_values(db,source)
      data = source.get_data(:md)
      counter = {}
      db.transaction do |database|
        database.prepare("insert into object_values 
          (source_id,attrib,object,value) values (?,?,?,?)") do |stmt|
          data.each do |object_id,object|
            object.each do |attrib,value|
              counter[attrib] = counter[attrib] ? counter[attrib] + 1 : 1
              stmt.execute(source.source_id.to_i,attrib,object_id,value)
            end
          end
        end
      end
      counter
    end
     
    def self.refs_to_s(refs)
      str = ''
      refs.sort.each do |name,value|
        str << "#{name},#{value},"
      end
      str[0..-2]
    end
    
    def self.populate_sources_table(db,sources_refs) 
      db.transaction do |database|
        database.prepare("insert into sources
          (source_id,name,priority,partition,sync_type,source_attribs,metadata) 
          values (?,?,?,?,?,?,?)") do |stmt|
          sources_refs.each do |source_name,ref|
            s = ref[:source]
            stmt.execute(s.source_id,s.name,s.priority,s.partition_type,
              s.sync_type,refs_to_s(ref[:refs]),s.get_value(:metadata))
          end
        end
      end
    end  
    
    def self.create_sqlite_data_file(bulk_data,ts)
      sources_refs = {}
      schema,index,bulk_data.dbfile = get_file_args(bulk_data.name,ts)
      FileUtils.mkdir_p(File.dirname(bulk_data.dbfile))
      db = SQLite3::Database.new(bulk_data.dbfile)
      db.execute_batch(File.open(schema,'r').read)
      src_counter = 1
      bulk_data.sources.members.sort.each do |source_name|
        timer = start_timer("start importing sqlite data for #{source_name}")
        source = Source.load(source_name,{:app_id => bulk_data.app_id,
          :user_id => bulk_data.user_id})
        source.source_id = src_counter
        src_counter += 1
        source_attrib_refs = import_data_to_object_values(db,source)
        sources_refs[source_name] = 
          {:source => source, :refs => source_attrib_refs}
        lap_timer("finished importing sqlite data for #{source_name}",timer)
      end
      populate_sources_table(db,sources_refs)
      db.execute_batch(File.open(index,'r').read)
      compress("#{bulk_data.dbfile}.rzip",bulk_data.dbfile)
    end
    
    def self.create_hsql_data_file(bulk_data,ts)
      schema,index,dbfile = get_file_args(bulk_data.name,ts)
      hsql_file = dbfile + ".hsqldb"
      raise Exception.new("Error running hsqldata") unless 
        system('java','-cp', File.join(File.dirname(__FILE__),'..','..','..','vendor','hsqldata.jar'),
        'com.rhomobile.hsqldata.HsqlData', dbfile, hsql_file, schema, index)
    end
    
    def self.get_file_args(bulk_data_name,ts)
      schema = BulkData.schema_file
      index = BulkData.index_file
      dbfile = File.join(Rhosync.data_directory,bulk_data_name+'_'+ts+'.data')
      [schema,index,dbfile]
    end
    
    def self.compress(archive,file)
      Zip::ZipFile.open(archive, 'w') do |zipfile|
        zipfile.add(File.basename(file),file)
      end
    end
  end
end