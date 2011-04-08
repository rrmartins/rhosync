require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "PingJob" do
  include TestHelpers
  let(:test_app_name) { 'application' }

  let(:source) { 'Product' }
  let(:user_id) { 5 }
  let(:client_id)  { 1 }
  let(:product1) { {'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99'} }
  let(:product2) { {'name' => 'G2', 'brand' => 'Android', 'price' => '99.99'} }
  let(:product3) { {'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99'} }  
  let(:product4) { {'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'} }
  let(:products)     { {'1' => product1,'2' => product2,'3'=> product3} }

  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end
  
  before(:each) do # "RhosyncHelper"
    Store.create
    Store.db.flushdb
  end
  
  #   it_should_behave_like "DBObjectsHelper"
  before(:each) do
    @a_fields = { :name => test_app_name }
    # @a = App.create(@a_fields)
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
  end

  
  it "should perform apple ping" do
    params = {"user_id" => @u.id, "api_token" => @api_token,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    Apple.should_receive(:ping).once.with({'device_pin' => @c.device_pin,
      'device_port' => @c.device_port}.merge!(params))
    PingJob.perform(params)
  end
  
  it "should perform blackberry ping" do
    params = {"user_id" => @u.id, "api_token" => @api_token,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @c.device_type = 'blackberry'
    Blackberry.should_receive(:ping).once.with({'device_pin' => @c.device_pin,
      'device_port' => @c.device_port}.merge!(params))
    PingJob.perform(params)
  end
  
  it "should skip ping for empty device_type" do
    params = {"user_id" => @u.id, "api_token" => @api_token,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @c.device_type = nil
    PingJob.should_receive(:log).once.with("Skipping ping for non-registered client_id '#{@c.id}'...")
    lambda { PingJob.perform(params) }.should_not raise_error
  end
  
  it "should skip ping for empty device_pin" do
    params = {"user_id" => @u.id, "api_token" => @api_token,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @c.device_type = 'blackberry'
    @c.device_pin = nil
    PingJob.should_receive(:log).once.with("Skipping ping for non-registered client_id '#{@c.id}'...")
    lambda { PingJob.perform(params) }.should_not raise_error
  end
  
end