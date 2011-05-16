# When shared examples are called as  
#   it_behaves_like "SharedRhosyncHelper", :rhosync_data => false
# then :rhosync_data group (@product1, ..., @data) skipped.
# To enable this group call examples as
#   it_behaves_like "SharedRhosyncHelper", :rhosync_data => true
shared_examples_for "SharedRhosyncHelper" do |params|
  include TestHelpers      
  # "TestappHelper"
  let(:test_app_name) { 'application' }  
  # "RhosyncHelper"
  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__), '..', '..', 'vendor')
    end
  end
  
  before(:each) do
    # "RhosyncHelper" 
    Store.create
    Store.db.flushdb
        
    # "DBObjectsHelper"
    @a_fields = { :name => test_app_name }
    @a = (App.load(test_app_name) || App.create(@a_fields))
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'Apple',
      :device_pin => 'abcd',
      :device_port => '3333',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.load(@s_fields[:name],@s_params)
    @s = Source.create(@s_fields,@s_params) if @s.nil?
    @s1 = Source.load('FixedSchemaAdapter',@s_params)
    @s1 = Source.create({:name => 'FixedSchemaAdapter'},@s_params) if @s1.nil?
    @s2 = Source.load('Product2',@s_params)
    @s2 = Source.create({:name => 'Product2'},@s_params) if @s2.nil?
    config = Rhosync.source_config["sources"]['FixedSchemaAdapter']
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources.members)
    @a.users << @u.id
    
    # "RhosyncDataHelper"  
    if params && params[:rhosync_data] 
      @source = 'Product'
      @user_id = 5
      @client_id = 1

      @product1 = { 'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99' }
      @product2 = { 'name' => 'G2', 'brand' => 'Android', 'price' => '99.99' }
      @product3 = { 'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99' }
      @product4 = { 'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'}

      @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
    end
  end
end

shared_examples_for "BenchSpecHelper" do
  before(:each) do
    Store.create
    Store.db.flushdb

    @product1 = { 'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99' }
    @product2 = { 'name' => 'G2', 'brand' => 'Android', 'price' => '99.99' }
    @product3 = { 'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99' }
    @product4 = { 'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'}

    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end
end

shared_examples_for "ApiHelper" do
  include Rack::Test::Methods
  include Rhosync
  include TestHelpers    

  let(:test_app_name) { 'application' }
  
  before(:each) do
    Store.create
    Store.db.flushdb

    require File.join(get_testapp_path, test_app_name)
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(rhosync.base_directory,'..','..','..','vendor')
    end
    Rhosync::Server.set :environment, :test
    Rhosync::Server.set :run, false
    Rhosync::Server.set :secret, "secure!"
    @api_token = User.load('rhoadmin').token_id

    @a_fields = { :name => test_app_name }
    @a = (App.load(test_app_name) || App.create(@a_fields))
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'Apple',
      :device_pin => 'abcd',
      :device_port => '3333',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.load(@s_fields[:name],@s_params)
    @s = Source.create(@s_fields,@s_params) if @s.nil?
    @s1 = Source.load('FixedSchemaAdapter',@s_params)
    @s1 = Source.create({:name => 'FixedSchemaAdapter'},@s_params) if @s1.nil?
    config = Rhosync.source_config["sources"]['FixedSchemaAdapter']
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources.members)
    @a.users << @u.id

    @source = 'Product'
    @user_id = 5
    @client_id = 1

    @product1 = { 'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99' }
    @product2 = { 'name' => 'G2', 'brand' => 'Android', 'price' => '99.99' }
    @product3 = { 'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99' }
    @product4 = { 'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'}

    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end
end