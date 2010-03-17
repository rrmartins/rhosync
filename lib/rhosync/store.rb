module Rhosync
  class Store
    RESERVED_ATTRIB_NAMES = ["attrib_type", "id"] unless defined? RESERVED_ATTRIB_NAMES
    @@db = nil
    
    class << self
      def db; @@db || @@db = _get_redis end
      
      def db=(server=nil)
        @@db = _get_redis(server)
      end
      
      def create(server=nil)
        @@db ||= _get_redis(server)
        raise "Error connecting to Redis store." unless @@db and @@db.is_a?(Redis)
      end
  
      # Adds set with given data, replaces existing set
      # if it exists or appends data to the existing set
      # if append flag set to true
      def put_data(dockey,data={},append=false)
        if dockey and data
          flash_data(dockey) unless append
          # Inserts a hash or array
          if data.is_a?(Hash)
            @@db.pipelined do |pipeline|
              data.each do |key,value|
                value.each do |attrib,value|
                  unless _is_reserved?(attrib,value)
                    pipeline.sadd(dockey,setelement(key,attrib,value))
                  end
                end
              end
            end
          else
            @@db.pipelined do |pipeline|
              data.each do |value|
                pipeline.sadd(dockey,value)
              end
            end
          end
        end
        true
      end
    
      # Adds a simple key/value pair
      def put_value(dockey,value)
        if dockey
          @@db.del(dockey)
          @@db.set(dockey,value.to_s) if value
        end
      end
    
      # Retrieves value for a given key
      def get_value(dockey)
        @@db.get(dockey) if dockey
      end
  
      # Retrieves set for given dockey,source,user
      def get_data(dockey,type=Hash)
        res = type == Hash ? {} : []
        if dockey
          @@db.smembers(dockey).each do |element|
            if type == Hash
              key,attrib,value = getelement(element)
              res[key] = {} unless res[key]
              res[key].merge!({attrib => value})
            else
              res << element
            end
          end
          res
        end
      end
  
      # Retrieves diff data hash between two sets
      def get_diff_data(src_dockey,dst_dockey,p_size=nil)
        res = {}
        if src_dockey and dst_dockey
          @@db.sdiff(dst_dockey,src_dockey).each do |element|
            key,attrib,value = getelement(element)
            res[key] = {} unless res[key]
            res[key].merge!({attrib => value})
          end
        end
        if p_size
          diff = {}
          page_size = p_size
          res.each do |key,item|
            diff[key] = item
            page_size -= 1
            break if page_size <= 0         
          end
          [diff,res.size]
        else  
          [res,res.size]
        end
      end

      # Deletes data from a given doctype,source,user
      def delete_data(dockey,data={})
        if dockey and data
          @@db.pipelined do |pipeline|
            data.each do |key,value|
              value.each do |attrib,val|
                pipeline.srem(dockey,setelement(key,attrib,val))
              end
            end
          end
        end
        true
      end
    
      # Deletes all keys matching a given mask
      def flash_data(keymask)
        @@db.keys(keymask).each do |key|
          @@db.del(key)
        end
      end
    
      # Returns array of keys matching a given keymask
      def get_keys(keymask)
        @@db.keys(keymask)
      end
    
      # Returns true if given item is a member of the given set
      def ismember?(setkey,item)
        @@db.sismember(setkey,item)
      end
      
      # Lock a given key and release when provided block is finished
      def lock(dockey,timeout=0)
        m_lock = get_lock(dockey,timeout)
        res = yield
        release_lock(dockey,m_lock)
        res
      end
    
      def get_lock(dockey,timeout=0)
        lock_key = _lock_key(dockey)
        current_time = Time.now.to_i
        if not @@db.setnx(lock_key,current_time+timeout+1)
          loop do
            if @@db.get(lock_key).to_i <= current_time and 
                @@db.getset(lock_key,current_time+timeout+1).to_i <= current_time
              break
            end
            sleep(1)
            current_time = Time.now.to_i
          end
        end
        current_time+timeout+1
      end
      
      # Due to redis bug #140, setnx always returns true so this doesn't work
      # def get_lock(dockey,timeout=0)
      #   lock_key = _lock_key(dockey)
      #   until @@db.setnx(lock_key,1) do 
      #     sleep(1) 
      #   end
      #   @@db.expire(lock_key,timeout+1)
      #   Time.now.to_i+timeout+1
      # end
      
      def release_lock(dockey,lock)
        @@db.del(_lock_key(dockey)) if (lock >= Time.now.to_i)
      end
      
      # Create a copy of srckey in dstkey
      def clone(srckey,dstkey)
        @@db.sdiffstore(dstkey,srckey,'')
      end
      
      # Rename srckey to dstkey
      def rename(srckey,dstkey)
        @@db.rename(srckey,dstkey) if @@db.exists(srckey)
      end
      
      private
      def _get_redis(server=nil)
        if server and server.is_a?(String)
          host,port,db,password = server.split(':')
          Redis.new(:thread_safe => true, :host => host,
            :port => port, :db => db, :password => password)
        else
          Redis.new(:thread_safe => true)
        end
      end
      
      def _lock_key(dockey)
        "#{dockey}:lock"
      end
          
      def _is_reserved?(attrib,value) #:nodoc:
        RESERVED_ATTRIB_NAMES.include? attrib
      end
    end
  end
end  