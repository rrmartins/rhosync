module RhosyncStore  
  class ReadState < Model
    field :poll_interval,:integer
    field :refresh_time,:integer
  
    def self.create(fields)
      fields[:id] = get_id(fields)
      fields.delete(:app_id)
      fields.delete(:user_id)
      fields.delete(:source_name)
      fields[:poll_interval] ||= 300
      fields[:refresh_time] ||= Time.now.to_i
      super(fields,{})
    end
  
    def self.load(params)
      super(get_id(params),{})
    end
    
    def self.delete(app_id)
      Store.flash_data("#{class_prefix(self)}:#{app_id}:*")
    end

    private
    def self.get_id(params)
      "#{params[:app_id]}:#{params[:user_id]}:#{params[:source_name]}"
    end
  end
end