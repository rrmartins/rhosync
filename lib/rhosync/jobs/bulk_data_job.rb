require 'zip/zip'
require 'zlib'
if defined?(JRUBY_VERSION)
  require 'jdbc/sqlite3'
  require 'active_record'
else
  require 'sqlite3'
end
  
if defined?(JRUBY_VERSION)
  def execute_batch(queries) 
    queries.split(';').each do |sql|
      begin 
        ActiveRecord::Base.connection.execute("#{sql}\n") unless sql.blank?
      rescue 
        ActiveRecord::StatementInvalid log "execute_batch: warning: #{$!}"
      end 
    end
  end
  def quote_string(str)
    str.gsub(/'/, "''")
  end
    
  # class Source < ActiveRecord::Base
  # end
      
end  
    
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
          log "bulk_data.dbfile:  #{bulk_data.dbfile}"
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
        log "Bulk data job raised: #{e.message}"
        log e.backtrace.join("\n")
        raise e
      end
    end
    
    def self.import_data_to_object_values(db,source)
      data = source.get_data(:md)
      counter = {}
      db.transaction do |database|
        if defined?(JRUBY_VERSION)
          ins_query = %Q{insert into object_values (source_id,attrib,object,value) values (?,?,?,?)}.gsub('?', '"%s"')
          data.each do |object_id,object|
            object.each do |attrib,value|
              counter[attrib] = counter[attrib] ? counter[attrib] + 1 : 1              
              # FIXME:  
              query = (ins_query % [source.source_id.to_i,attrib,object_id,value]).gsub('\'\'','NULL') # ...,'','') =>  
              ActiveRecord::Base.connection.execute(query)
            end
          end
        else  
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
      end
      counter
    end
    
    # Loads data into fixed schema table based on source settings
    def self.import_data_to_fixed_schema(db,source)
      data = source.get_data(:md)
      counter = {}
      columns,qm = [],[]
      create_table = ["\"object\" varchar(255) PRIMARY KEY"]
      schema = JSON.parse(source.schema)
      
      db.transaction do |database|
        # Create a table with columns specified by 'property' array in settings
        schema['property'].each do |key,value|
          create_table << "\"#{key}\" varchar default NULL" 
          columns << key
          qm << '?'
        end

        if defined?(JRUBY_VERSION)
          ActiveRecord::Base.connection.execute("CREATE TABLE #{source.name}(#{create_table.join(",")} );") 
        else  
          database.execute("CREATE TABLE #{source.name}(#{create_table.join(",")} );")
        end

        # Insert each object as single row in fixed schema table
        if defined?(JRUBY_VERSION)
          ins_query = "insert into #{source.name} (object,#{columns.join(',')}) values (?,#{qm.join(',')})".gsub('?', '"%s"')
          data.each do |obj,row|
            args = [obj]
            columns.each do |col|
              args << row[col]
            end
            # FIXME:
            query = (ins_query % args).gsub('""','NULL')
            ActiveRecord::Base.connection.execute(query)
          end          
        else
          database.prepare("insert into #{source.name} 
            (object,#{columns.join(',')}) values (?,#{qm.join(',')})") do |stmt|
            data.each do |obj,row|
              args = [obj]
              columns.each do |col|
                args << row[col]
              end
              stmt.execute(args)
            end
          end
        end    
        
        # Create indexes for specified columns in settings 'index'
        schema['index'].each do |key,value|
          val2 = ""
          value.split(',').each do |col|
            val2 += ',' if val2.length > 0
            val2 += "\"#{col}\""
          end

          if defined?(JRUBY_VERSION)
            ActiveRecord::Base.connection.execute("CREATE INDEX #{key} on #{source.name} (#{val2});")
          else
            database.execute("CREATE INDEX #{key} on #{source.name} (#{val2});")
          end
        end if schema['index']
        
        # Create unique indexes for specified columns in settings 'unique_index'
        schema['unique_index'].each do |key,value|
          val2 = ""
          value.split(',').each do |col|
            val2 += ',' if val2.length > 0
            val2 += "\"#{col}\""
          end
        
          if defined?(JRUBY_VERSION)
            ActiveRecord::Base.connection.execute("CREATE UNIQUE INDEX #{key} on #{source.name} (#{val2});")
          else
            database.execute("CREATE UNIQUE INDEX #{key} on #{source.name} (#{val2});")
          end
        end if schema['unique_index']
      end
    
      return {}
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
        if defined?(JRUBY_VERSION) # FIXME:
          ins_query = "insert into sources
            (source_id,name,sync_priority,partition,sync_type,source_attribs,metadata,schema,blob_attribs,associations) 
            values (?,?,?,?,?,?,?,?,?,?)".gsub('?', "'%s'")
          sources_refs.each do |source_name,ref|
            s = ref[:source]            
            params = [s.source_id,s.name,s.priority,s.partition_type,
              s.sync_type,refs_to_s(ref[:refs]),s.get_value(:metadata),s.schema,s.blob_attribs,s.has_many]          
            # TODO:
            query = (ins_query % params).gsub('\'\'','NULL')
            ActiveRecord::Base.connection.execute(query)
          end
          # TODO:
        else
          database.prepare("insert into sources
            (source_id,name,sync_priority,partition,sync_type,source_attribs,metadata,schema,blob_attribs,associations) 
            values (?,?,?,?,?,?,?,?,?,?)") do |stmt|
            sources_refs.each do |source_name,ref|
              s = ref[:source]
              stmt.execute(s.source_id,s.name,s.priority,s.partition_type,
                s.sync_type,refs_to_s(ref[:refs]),s.get_value(:metadata),s.schema,s.blob_attribs,s.has_many)
            end
          end
        end
      end
    end  
    
    def self.create_sqlite_data_file(bulk_data,ts)
      sources_refs = {}
      schema,index,bulk_data.dbfile = get_file_args(bulk_data.name,ts)
      FileUtils.mkdir_p(File.dirname(bulk_data.dbfile))

      if defined?(JRUBY_VERSION) # FIXME:
        ActiveRecord::Base.establish_connection( 
          :adapter => "jdbcsqlite3", 
          :database => "#{bulk_data.dbfile}"
        )
        db = ActiveRecord::Base.connection          
        execute_batch(File.open(schema,'r').read)        
      else   
        db = SQLite3::Database.new(bulk_data.dbfile)
        db.execute_batch(File.open(schema,'r').read)
      end

      src_counter = 1
      bulk_data.sources.members.sort.each do |source_name|
        timer = start_timer("start importing sqlite data for #{source_name}")
        source = Source.load(source_name,{:app_id => bulk_data.app_id,
          :user_id => bulk_data.user_id})
        source.source_id = src_counter
        src_counter += 1
        source_attrib_refs = nil
        if source.schema
          source_attrib_refs = import_data_to_fixed_schema(db,source)
        else
          source_attrib_refs = import_data_to_object_values(db,source)
        end
        sources_refs[source_name] = 
          {:source => source, :refs => source_attrib_refs}
        lap_timer("finished importing sqlite data for #{source_name}",timer)
      end
      populate_sources_table(db,sources_refs)
      
      if defined?(JRUBY_VERSION)
        execute_batch(File.open(index,'r').read)
        execute_batch( "VACUUM;");
      else         
        db.execute_batch(File.open(index,'r').read)
        db.execute_batch( "VACUUM;");
        db.close
      end
      
      compress("#{bulk_data.dbfile}.rzip",bulk_data.dbfile)
      gzip_compress("#{bulk_data.dbfile}.gzip",bulk_data.dbfile)
    end
    
    def self.create_hsql_data_file(bulk_data,ts)
      schema,index,dbfile = get_file_args(bulk_data.name,ts)
      hsql_file = dbfile + ".hsqldb"
      cmd = ['java','-cp', File.join(File.expand_path(Rhosync.vendor_directory),'hsqldata.jar'),
        'com.rhomobile.hsqldata.HsqlData', dbfile, hsql_file].join(" ")
      log "Running hsqldata: #{cmd.to_s}"
      raise Exception.new("Error running hsqldata") unless 
        system(
          'java','-cp', 
          File.join(File.expand_path(Rhosync.vendor_directory),'hsqldata.jar'),
          'com.rhomobile.hsqldata.HsqlData',
          dbfile, hsql_file
        )
      gzip_compress("#{hsql_file}.data.gzip","#{hsql_file}.data")
    end
    
    def self.get_file_args(bulk_data_name,ts)
      schema = BulkData.schema_file
      index = BulkData.index_file
      dbfile = File.join(Rhosync.data_directory,bulk_data_name+'_'+ts+'.data')
      [schema,index,dbfile]
    end
    
    def self.compress(archive,file)
      Zip::ZipFile.open(archive, 'w') do |zipfile|
        zipfile.add(URI.escape(File.basename(file)),file)
      end
    end
    
    def self.gzip_compress(archive,file)
      data = File.new(file, "rb")
      File.open(archive, 'wb') do |f|
        gz = Zlib::GzipWriter.new(f)
        gz.write data.read
        gz.close
      end
      data.close
    end
    
  end
end