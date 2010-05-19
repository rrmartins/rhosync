module Rhosync
  class SourceAdapter
    attr_accessor :result
  end
  
  module TestMethods
    def setup_test_for(adapter,user_id)
      app_id = 'application'
      s_fields = {
        :user_id => user_id,
        :app_id => app_id
      }
      c_fields = {
        :device_type => 'iPhone',
        :device_pin => 'abcd',
        :device_port => '3333',
        :user_id => user_id,
        :app_id => app_id 
      }
      @u = User.create(:login => user_id)
      @s = Source.load(adapter.to_s,s_fields)
      @c = Client.create(c_fields,{:source_name => adapter.to_s})
      @ss = SourceSync.new(@s)
    end
    
    def test_query
      @ss.process_query
      return md
    end
    
    def query_errors
      @s.get_data(:errors)
    end
    
    def test_create(record)
      @c.put_data(:create,{'temp-id' => record})
      @ss.create(@c.id)
      links = @c.get_data(:create_links)['temp-id']
      links ? links['l'] : nil
    end
    
    def create_errors
      @c.get_data(:create_errors)
    end
    
    def test_update(record)
      @c.put_data(:update,record)
      @ss.update(@c.id)
    end
    
    def update_errors
      @c.get_data(:update_errors)
    end
    
    def test_delete(record)
      @c.put_data(:delete,record)
      @ss.delete(@c.id)
    end
    
    def delete_errors
      @c.get_data(:delete_errors)
    end
    
    def md
      @s.get_data(:md)
    end
    
    def cd
      @c.get_data(:cd)
    end
  end
end