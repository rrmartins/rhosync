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
        :device_type => 'Apple',
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
      res = @ss.process_query
      return @s.is_pass_through? ? res : md
    end
    
    # Executes the adapter's query method and returns 
    # the metadata stored in redis
    # For example, if your source adapter metadata method was:
    # def metadata
    #     row1 = { 
    #       :label => 'Address 1',
    #       :value => '123 fake street',
    #       :name => 'address1',
    #       :type => 'labeledrow' 
    #     }
    #     table = { 
    #       :label => 'Table',
    #       :type => 'table',
    #       :children => [ row1, row1, row1 ] 
    #     }
    #     view = { 
    #       :title => 'UI meta panel',
    #       :type => 'iuipanel',
    #       :children => [table] 
    #     }
    #   return the definition as JSON
    #    {'index' => view}.to_json
    # 
    # test_metadata would return:
    # { 
    #   {'index' => view}.to_json
    # }
    def test_metadata
     @ss.process_query
     return @s.get_value(:metadata)
    end
    
    # Executes the adapter's schema method and returns 
    # the schema stored in redis
    # For example, if your source adapter schema method was:
    # def schema
    # {
    #     'version' => '1.0',
    #     'property' => {
    #       'name' => 'string',
    #       'brand' => 'string',
    #       'price' => 'string',
    #       'image_url_cropped' => 'blob,overwrite',
    #       'image_url' => 'blob'
    #      },
    #     'index' => {
    #       'by_name_brand' => 'name,brand'
    #     },
    #     'unique_index' => {
    #       'by_price' => 'price'
    #     }
    # }.to_json
    # test_schema would return the above
    def test_schema
      @ss.process_query
      return @s.get_value(:schema)
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
      if @s.is_pass_through?
        @ss.pass_through_cud({'create'=> {'temp-id' => record}},nil)
      else
        @c.put_data(:create,{'temp-id' => record})
        @ss.process_cud(@c.id)
        links = @c.get_data(:create_links)['temp-id']
        links ? links['l'] : nil
      end
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
      if @s.is_pass_through?
        @ss.pass_through_cud({'update'=> record },nil)
      else
        @c.put_data(:update,record)
        @ss.process_cud(@c.id)
      end
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
      if @s.is_pass_through?
        @ss.pass_through_cud({'delete'=> record },nil)
      else
        @c.put_data(:delete,record)
        @ss.process_cud(@c.id)
      end
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