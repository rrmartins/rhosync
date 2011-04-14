require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "Store" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    describe "store methods" do
      it "should create db class method" do
        Store.db.class.name.should match(/Redis/)
      end

      it "should set redis connection" do
        Store.db = nil
        Store.db = 'localhost:6379'
        Store.db.client.host.should == 'localhost'
        Store.db.client.port.should == 6379
      end

      it "should create default redis connection" do
        Store.db = nil
        Store.db.class.name.should match(/Redis/)
      end

      it "should assign redis to existing redis" do
        Store.db = Redis.new(:timeout => 60)
        Store.db.client.timeout.should == 60
      end

      it "should create redis connection based on ENV" do
        ENV[REDIS_URL] = 'redis://localhost:6379'
        Redis.should_receive(:connect).with(:url => 'redis://localhost:6379').and_return { Redis.new }
        Store.db = nil
        Store.db.should_not == nil
        ENV.delete(REDIS_URL)
      end

      it "should add simple data to new set" do
        Store.put_data(@s.docname(:md),@data).should == true
        Store.get_data(@s.docname(:md)).should == @data
      end

      it "should set_data and get_data" do
        Store.set_data('foo', @data)
        Store.get_data('foo').should == @data
      end

      it "should put_data with simple data" do
        data = { '1' => { 'hello' => 'world' } }
        Store.put_data('mydata', data)
        Store.get_data('mydata').should == data
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

      it "should incr a key" do
        Store.incr('foo').should == 1
      end

      it "should decr a key" do
        Store.set_value('foo', 10)
        Store.decr('foo').should == 9
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
        Store.get_diff_data(@s.docname(:md),@c.docname(:cd)).should == [expected,1]
      end

      it "should return attributes modified and missed in doc2" do
        Store.put_data(@s.docname(:md),@data).should == true
        Store.get_data(@s.docname(:md)).should == @data

        @product2['price'] = '59.99'
        expected = { '2' => { 'price' => '99.99' },'3' => @product3 }
        @data1,@data1['1'],@data1['2'] = {},@product1,@product2

        Store.put_data(@c.docname(:cd),@data1)
        Store.get_data(@c.docname(:cd)).should == @data1
        Store.get_diff_data(@c.docname(:cd),@s.docname(:md)).should == [expected,2]
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
        m_lock = Store.get_lock(doc)
        pid = Process.fork do
          Store.db = Redis.new
          t_lock = Store.get_lock(doc)
          Store.put_data(doc,{'1'=>@product1},true)
          Store.release_lock(doc,t_lock) 
          Process.exit(0)
        end
        Store.put_data(doc,{'2'=>@product2},true)
        Store.get_data(doc).should == {'2'=>@product2}
        Store.release_lock(doc,m_lock)
        Process.waitpid(pid)
        m_lock = Store.get_lock(doc)
        Store.get_data(doc).should == {'1'=>@product1,'2'=>@product2}
      end

      it "should lock key for timeout" do
        doc = "locked_data"
        Store.db.set "lock:#{doc}", Time.now.to_i+3
        Store.should_receive(:sleep).at_least(:once).with(1).and_return { sleep 1 }
        m_lock = Store.get_lock(doc,2)
      end

      it "should lock document in block" do
        doc = "locked_data"
        Store.lock(doc,0) do
          Store.put_data(doc,{'2'=>@product2})
          Store.get_data(doc).should == {'2'=>@product2}
        end
      end

      it "should create clone of set" do
        set_state('abc' => @data)
        Store.clone('abc','def')
        verify_result('abc' => @data,'def' => @data)
      end

      it "should rename a key" do
        set_state('key1' => @data)
        Store.rename('key1','key2')
        verify_result('key1' => {}, 'key2' => @data)
      end

      it "should not fail to rename if key doesn't exist" do
        Store.rename('key1','key2')
        Store.db.exists('key1').should be_false
        Store.db.exists('key2').should be_false      
      end
    end
  end  
end