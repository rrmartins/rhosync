require File.join(File.dirname(__FILE__),'spec_helper')

describe "RhosyncStore" do
  
  it_should_behave_like "SourceAdapterHelper"
  
  describe "store methods" do
    it "should add simple data to new set" do
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md)).should == @data
    end
    
    it "should add simple array data to new set" do
      @data = ['1','2','3']
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md),Array).sort.should == @data
    end
  
    it "should replace simple data to existing set" do
      new_data,new_data['3'] = {},{'name' => 'Droid','brand' => 'Google'}
      Store.put_data(@s.docname(:md),@data).should == true
      Store.put_data(@s.docname(:md),new_data)
      Store.get_data(@s.docname(:md)).should == new_data
    end
    
    it "should put_value and get_value" do
      Store.put_value('foo','bar')
      Store.get_value('foo').should == 'bar'
    end
    
    it "should return true/false if element ismember of a set" do
      Store.put_data('foo',['a'])
      Store.ismember?('foo','a').should == true
      
      Store.ismember?('foo','b').should == false
    end
    
    it "should return attributes modified in doc2" do
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md)).should == @data
    
      @product3['price'] = '59.99'
      expected = { '3' => { 'price' => '59.99' } }
      @data1,@data1['1'],@data1['2'],@data1['3'] = {},@product1,@product2,@product3
    
      Store.put_data(@c.docname(:cd),@data1)
      Store.get_data(@c.docname(:cd)).should == @data1
      Store.get_diff_data(@s.docname(:md),@c.docname(:cd)).should == expected
    end
  
    it "should return attributes modified and missed in doc2" do
      Store.put_data(@s.docname(:md),@data).should == true
      Store.get_data(@s.docname(:md)).should == @data
    
      @product2['price'] = '59.99'
      expected = { '2' => { 'price' => '99.99' },'3' => @product3 }
      @data1,@data1['1'],@data1['2'] = {},@product1,@product2
    
      Store.put_data(@c.docname(:cd),@data1)
      Store.get_data(@c.docname(:cd)).should == @data1
      Store.get_diff_data(@c.docname(:cd),@s.docname(:md)).should == expected
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
    
      Store.put_data(@s.docname(:md),@data1).should == true
      Store.get_data(@s.docname(:md)).should == @data
    end
    
    it "should flash_data" do
      Store.put_data(@s.docname(:md),@data)
      Store.flash_data(@s.docname(:md))
      Store.get_data(@s.docname(:md)).should == {}
    end
    
    it "should get_keys" do
      expected = ["doc1:1:1:1:source1", "doc1:1:1:1:source2"]
      Store.put_data(expected[0],@data)
      Store.put_data(expected[1],@data)
      Store.get_keys('doc1:1:1:1:*').sort.should == expected
    end
    
    it "should lock document" do
      doc = "locked_data"
      m_lock = Store.get_lock(doc,1,"M")
      th = Thread.new do 
        t_lock = Store.get_lock(doc,1,"T")
        Store.put_data(doc,{'1'=>@product1},true)
        Store.release_lock(doc,t_lock,"T") 
      end
      Store.put_data(doc,{'2'=>@product2},true)
      Store.get_data(doc).should == {'2'=>@product2}
      th.alive?.should == true
      Store.release_lock(doc,m_lock,"M")
      sleep(1)
      m_lock = Store.get_lock(doc,1,"M")
      Store.get_data(doc).should == {'1'=>@product1,'2'=>@product2}
      th.alive?.should == false
    end
    
  end
end