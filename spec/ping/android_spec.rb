require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Android" do
  include TestHelpers
  let(:test_app_name) { 'application' }  

  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end

  before(:each) do # "RhosyncHelper"
    Store.create
    Store.db.flushdb
  end
  
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
  # ----------------------------------------------
  
  before do
    @params = {"device_pin" => @c.device_pin,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    post = mock('post')
    post.stub!(:new).and_return(post)
    post.stub!(:set_form_data)
    Net::HTTP::Post.stub!(:new).and_return(post)
    
    @http = mock('http')
    @http.stub!(:request)
    @http.stub!(:use_ssl=)
    @http.stub!(:verify_mode=)
    @http.stub!(:start).and_yield(@http)
    Net::HTTP.stub!(:new).and_return(@http)
  end
  
  it "should ping android" do
    Android.ping(@params)
  end
  
  it "should ping android with connection error" do
    error = 'Connection refused'
    @http.stub!(:request).and_return { raise SocketError.new(error) }
    Android.should_receive(:log).once.with("Error while sending ping: #{error}")
    lambda { Android.ping(@params) }.should raise_error(SocketError,error)
  end
  
  it "should compute c2d_message" do
    expected = {'registration_id' => @c.device_pin, 'collapse_key' => "RAND_KEY",
      'data.do_sync' => @s.name,
      'data.alert' => "hello world",
      'data.vibrate' => '5',
      'data.sound' => "hello.mp3"}
    actual = Android.c2d_message(@params)
    actual['collapse_key'] = "RAND_KEY" unless actual['collapse_key'].nil?
    actual.should == expected
  end
  
  it "should trim empty or nil params from c2d_message" do
    expected = {'registration_id' => @c.device_pin, 'collapse_key' => "RAND_KEY",
      'data.vibrate' => '5', 'data.do_sync' => '', 'data.sound' => "hello.mp3"}
    params = {"device_pin" => @c.device_pin,
      "sources" => [], "message" => '', "vibrate" => '5', "sound" => 'hello.mp3'}
    actual = Android.c2d_message(params)
    actual['collapse_key'] = "RAND_KEY" unless actual['collapse_key'].nil?
    actual.should == expected
  end
end
