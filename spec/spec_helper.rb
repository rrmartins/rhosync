$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'
include RhosyncStore

describe "RhosyncStoreHelper", :shared => true do
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
  end
  
  before(:all) do
    RhosyncStore.add_adapter_path(File.join(File.dirname(__FILE__),'apps','rhotestapp','sources'))
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
    
    @mdoc = Document.new('md',@app_id,@user_id,@client_id,@source)
    @cdoc = Document.new('cd',@app_id,@user_id,@client_id,@source)
  end
end  

describe "SourceAdapterHelper", :shared => true do
  it_should_behave_like "RhosyncStoreDataHelper"
  
  ERROR = '0_broken_object_id' unless defined? ERROR
  
  before(:each) do
    @a_fields = { :name => 'testapp' }
    @a = App.create(@a_fields)
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'iPhone',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @c = Client.create(@c_fields)
    @u.clients << @c.id
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
      :user_id => @u.id,
      :app_id => @a.id
    }
    @s = Source.create(@s_fields)
    @a.sources << @s.id
    @a.users << @u.id
  end
  
  def do_post(url,params)
    post url, params.to_json, {'CONTENT_TYPE'=>'application/json'}
  end
  
  def set_test_data(dockey,data,error_message=nil,error_name='wrongname')
    if error_message
      error = {'an_attribute'=>error_message,'name'=>error_name} 
      data.merge!({ERROR=>error})
    end  
    data.each { |key,value| value['rhomobile.rhoclient'] = @c.id.to_s }
    @a.store.put_data(dockey,data)
    data
  end
  
  def verify_result(result)
    result.each do |dockey,expected|
      expected[ERROR].delete('rhomobile.rhoclient') if expected[ERROR]
      @a.store.get_data(dockey).should == expected
    end
  end
end

describe "StorageStateHelper", :shared => true do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @s.name = 'StorageStateAdapter'
  end
end