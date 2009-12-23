require File.join(File.dirname(__FILE__),'spec_helper')

describe "RhosyncStore" do
  
  it_should_behave_like  "RhosyncStoreDataHelper"
  
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
  end
  describe "store methods" do
    it "should add simple data to new set" do
      @store.put_data(@mdoc.get_key,@data).should == true
      @store.get_data(@mdoc.get_key).should == @data
    end
  
    it "should replace simple data to existing set" do
      new_data,new_data['3'] = {},{'name' => 'Droid','brand' => 'Google'}
      @store.put_data(@mdoc.get_key,@data).should == true
      @store.put_data(@mdoc.get_key,new_data)
      @store.get_data(@mdoc.get_key).should == new_data
    end
    
    it "should put_value and get_value" do
      @store.put_value('foo','bar')
      @store.get_value('foo').should == 'bar'
    end
    
    it "should return attributes modified in doc2" do
      @store.put_data(@mdoc.get_key,@data).should == true
      @store.get_data(@mdoc.get_key).should == @data
    
      @product3['price'] = '59.99'
      expected = { '3' => { 'price' => '59.99' } }
      @data1,@data1['1'],@data1['2'],@data1['3'] = {},@product1,@product2,@product3
    
      @store.put_data(@cdoc.get_key,@data1)
      @store.get_data(@cdoc.get_key).should == @data1
      @store.get_diff_data(@mdoc.get_key,@cdoc.get_key).should == expected
    end
  
    it "should return attributes modified and missed in doc2" do
      @store.put_data(@mdoc.get_key,@data).should == true
      @store.get_data(@mdoc.get_key).should == @data
    
      @product2['price'] = '59.99'
      expected = { '2' => { 'price' => '99.99' },'3' => @product3 }
      @data1,@data1['1'],@data1['2'] = {},@product1,@product2
    
      @store.put_data(@cdoc.get_key,@data1)
      @store.get_data(@cdoc.get_key).should == @data1
      @store.get_diff_data(@cdoc.get_key,@mdoc.get_key).should == expected
    end  
  
    it "should ignore reserved attributes" do
      @newproduct = {
        'name' => 'iPhone',
        'brand' => 'Apple',
        'price' => '199.99',
        'id' => 1234,
        'attrib_type' => 'someblob'
      }
    
      @data1 = {'1'=>@newproduct,'2'=>@product2,'3'=>@product3}
    
      @store.put_data(@mdoc.get_key,@data1).should == true
      @store.get_data(@mdoc.get_key).should == @data
    end
    
    it "should flash_data" do
      @store.put_data(@mdoc.get_key,@data)
      @store.flash_data(@mdoc.get_key)
      @store.get_data(@mdoc.get_key).should == {}
    end
    
    it "should get_keys" do
      expected = ["doc1:1:1:1:source1", "doc1:1:1:1:source2"]
      @store.put_data(expected[0],@data)
      @store.put_data(expected[1],@data)
      @store.get_keys('doc1:1:1:1:*').sort.should == expected
    end
  end
end