module Rhosync
  class SourceAdapter
    attr_accessor :result
  end
  
  module TestMethods
    # Initializes the source adapter under test for a given user, typically in a before(:each) block
    # setup_test_for(Product,'testuser') #=> 'testuser' will be used by rest of the specs
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
    
    # Executes the adapter's query method and returns 
    # the master document (:md) stored in redis
    # For example, if your source adapter query method was:
    # def query(params=nil)
    #   @result = { 
    #     "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
    #     "2"=>{"name"=>"Best", "industry"=>"Software"}
    #   }
    # end
    # 
    # test_query would return:
    # { 
    #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
    #   "2"=>{"name"=>"Best", "industry"=>"Software"}
    # }
    def test_query
      @ss.process_query
      return md
    end
    
    # Returns any errors stored in redis for the previous source adapter query
    # For example: {"query-error"=>{"message"=>"error connecting to web service!"}}
    def query_errors
      @s.get_data(:errors)
    end
    
    # Execute's the adapter's create method with a provided record and
    # returns the object string from the create method.  If the create method
    # returns a string, then a link will be saved for the device next time
    # it synchronizes.  This link can be tested here.
    #
    # For example, in your spec:
    # @product = {
    #  'name' => 'iPhone',
    #  'brand' => 'Apple',
    #  'price' => '$299.99',
    #  'quantity' => '5',
    #  'sku' => '1234'
    # }
    # new_product_id = test_create(@product)
    # create_errors.should == {}
    # md[new_product_id].should == @product
    # 
    # This will return the result of the adapter's create method.  The master 
    # document (:md) should also contain the new record.
    def test_create(record)
      @c.put_data(:create,{'temp-id' => record})
      @ss.create(@c.id)
      links = @c.get_data(:create_links)['temp-id']
      links ? links['l'] : nil
    end
    
    # Returns any errors stored in redis from the previous source adapter create
    # (same structure as query errors)
    def create_errors
      @c.get_data(:create_errors)
    end
    
    # Execute the source adapter's update method.
    # Takes a record as hash of hashes (object_id => object)
    # 
    # For example:
    # test_update({'4' => {'price' => '$199.99'}})
    # update_errors.should == {}
    # test_query
    # md[product_id]['price'].should == '$199.99'
    # 
    # This will call the adapter's update method for object_id '4'
    # NOTE: To test the master document, you will need to run def test_query
    # as shown above
    def test_update(record)
      @c.put_data(:update,record)
      @ss.update(@c.id)
    end
    
    # Returns any errors stored in redis from the previous source adapter update
    # (same structure as query errors)
    def update_errors
      @c.get_data(:update_errors)
    end
    
    # Execute the source adapter's delete method.
    # Takes a record as hash of hashes (object_id => object)
    #
    # For example:
    # @product = {
    #   'name' => 'iPhone',
    #   'brand' => 'Apple',
    #   'price' => '$299.99',
    #   'quantity' => '5',
    #   'sku' => '1234'
    # }
    # test_delete('4' => @product)
    # delete_errors.should == {}
    # md.should == {}
    # 
    # This will call the adapter's delete method for product '4'
    # NOTE: The master document (:md) will be updated and can be
    # verified as shown above.
    def test_delete(record)
      @c.put_data(:delete,record)
      @ss.delete(@c.id)
    end
    
    # Returns any errors stored in redis from the previous source adapter delete
    # (same structure as query errors)
    def delete_errors
      @c.get_data(:delete_errors)
    end
    
    # Returns the master document (:md) for the source adapter stored in redis.
    # This is equivalent to the @result hash of hashes structure.
    def md
      @s.get_data(:md)
    end
    
    # Returns the client document (:cd) for the source adapter + client under test.
    # The master document (:md) and client document (:cd) should be equal
    def cd
      @c.get_data(:cd)
    end
  end
end