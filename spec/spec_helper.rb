$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'
include RhosyncStore

describe "RhosyncStoreHelper", :shared => true do
  before(:each) do
    Store.create
    Store.db.flushdb
  end
end

describe "RhosyncStoreDataHelper", :shared => true do
  it_should_behave_like "RhosyncStoreHelper"
  
  before(:each) do
    @source = 'Product'
    @user_id = 5
    @client_id = 1
    @app_id = 2
    
    @product1 = {
      'name' => 'iPhone',
      'brand' => 'Apple',
      'price' => '199.99'
    }
    
    @product2 = {
      'name' => 'G2',
      'brand' => 'Android',
      'price' => '99.99'
    }

    @product3 = {
      'name' => 'Fuze',
      'brand' => 'HTC',
      'price' => '299.99'
    }
    
    @product4 = {
      'name' => 'Droid',
      'brand' => 'Android',
      'price' => '249.99'
    }
    
    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end
end  

describe "SourceAdapterHelper", :shared => true do
  it_should_behave_like "RhosyncStoreDataHelper"
  
  ERROR = '0_broken_object_id' unless defined? ERROR
  
  before(:each) do
    @a_fields = { :name => 'rhotestapp' }
    @a = App.create(@a_fields)
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'iPhone',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields)
    @c.source_name = @s_fields[:name]
    @u.clients << @c.id
    @s = Source.create(@s_fields)
    @a.sources << @s.id
    @a.users << @u.id
  end
  
  def do_post(url,params)
    post url, params.to_json, {'CONTENT_TYPE'=>'application/json'}
  end
  
  def dump_db_data(store)
    puts "*"*50 
    puts "DATA DUMP"
    puts "*"*50
    store.db.keys('*').sort.each do |key|
      next if not key =~ /md|cd/ 
      line = ""
      line << "#{key}: "
      type = store.db.type key
      if type == 'set'
        if not key =~ /sources|clients|users/
          line << "#{store.get_data(key).inspect}"
        else
          line << "#{store.db.smembers(key).inspect}"
        end  
      else
        line << "#{store.db.get key}"
      end
      puts line
    end
    puts "*"*50
  end
  
  def add_client_id(data)
    res = Marshal.load(Marshal.dump(data))
    res.each { |key,value| value['rhomobile.rhoclient'] = @c.id.to_s }
  end

  def add_error_object(data,error_message,error_name='wrongname')
    error = {'an_attribute'=>error_message,'name'=>error_name} 
    data.merge!({ERROR=>error})
    data
  end
      
  def set_state(state)
    state.each do |dockey,data|
      if data.is_a?(Hash) or data.is_a?(Array)
        Store.put_data(dockey,data)
      else
        Store.put_value(dockey,data)
      end
    end
  end
  
  def set_test_data(dockey,data,error_message=nil,error_name='wrongname')
    if error_message
      error = {'an_attribute'=>error_message,'name'=>error_name} 
      data.merge!({ERROR=>error})
    end  
    Store.put_data(dockey,data)
    data
  end
  
  def verify_result(result)
    result.each do |dockey,expected|
      if expected.is_a?(Hash)
        Store.get_data(dockey).should == expected
      elsif expected.is_a?(Array)
        Store.get_data(dockey,Array).should == expected
      else
        Store.get_value(dockey).should == expected
      end
    end
  end
end

describe "StorageStateHelper", :shared => true do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @s.name = 'StorageStateAdapter'
  end
end

describe "SpecBootstrapHelper", :shared => true do
  before(:all) do
    basedir = File.dirname(__FILE__)
    RhosyncStore.bootstrap(File.join(basedir,'apps'),File.join(basedir,'data'))
  end
end