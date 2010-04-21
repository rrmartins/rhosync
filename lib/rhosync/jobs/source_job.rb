module Rhosync
  class SourceJob
    class << self
      attr_accessor :queue
    end
    
    def self.perform(job_type,source_id,app_id,user_id,client_id,params)
      source = Source.load(source_id,{:app_id => app_id,:user_id => user_id})
      source_sync = SourceSync.new(source)
      case job_type.to_sym
      when :query then source_sync.do_query(params)
      when :cud then source_sync.do_cud(client_id)
      end    
    end
  end
end