module RhosyncStore
  class Store
    RESERVED_ATTRIB_NAMES = ["attrib_type", "id"] 
    @@db = nil

    def initialize
      @@db = Redis.new unless @@db
      raise "Error connecting to Redis store." unless @@db and @@db.is_a?(Redis)
    end
    
    def db; @@db end
  
    # Adds set with given data, replaces existing set
    # if it exists or appends data to the existing set
    # if append flag set to true
    def put_data(dockey,data={},append=false)
      if dockey
        flash_data("#{dockey}*") unless append
        # Inserts a hash or array
        if data.is_a?(Hash)
          data.each do |key,value|
            value.each do |attrib,value|
              unless _is_reserved?(attrib,value)
                @@db.sadd(dockey,setelement(key,attrib,value))
              end
            end
          end
        else
          data.each do |value|
            @@db.sadd(dockey,value)
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
    def get_diff_data(src_dockey,dst_dockey)
      res = {}
      if src_dockey and dst_dockey
        @@db.sdiff(dst_dockey,src_dockey).each do |element|
          key,attrib,value = getelement(element)
          res[key] = {} unless res[key]
          res[key].merge!({attrib => value})
        end
      end
      res
    end
    
    # Deletes data from a given doctype,source,user
    def delete_data(dockey,data={})
      if dockey
        if data.is_a?(Array) and not data.empty?
          # TODO: This will be very slow if the set is huge
          @@db.smembers(dockey).each do |member|
            key,attrib,value = getelement(member)
            @@db.srem(dockey,member) if data.include?(key)
          end
        else  
          data.each do |key,value|
            value.each do |attrib,val|
              @@db.srem(dockey,setelement(key,attrib,val))
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
    
    private  
    def _is_reserved?(attrib,value) #:nodoc:
      if RESERVED_ATTRIB_NAMES.include? attrib 
        Logger.error "Ignoring attrib-value pair: #{{attrib => value}.inspect}."
        true
      else
        false
      end
    end
  end
end  