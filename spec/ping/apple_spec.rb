require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Apple" do
  include TestHelpers
  let(:test_app_name) { 'application' }
    
  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end

  #it_should_behave_like "SourceAdapterHelper"
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
    @params = {"user_id" => @u.id, "api_token" => @api_token,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3',
      "device_pin" => @c.device_pin, "device_port" => @c.device_port}
    ssl_ctx = mock("ssl_ctx")
    ssl_ctx.stub!(:key=).and_return('key')
    ssl_ctx.stub!(:cert=).and_return('cert')
    OpenSSL::SSL::SSLContext.stub!(:new).and_return(ssl_ctx)
    OpenSSL::PKey::RSA.stub!(:new)
    OpenSSL::X509::Certificate.stub!(:new)
    
    tcp_socket = mock("tcp_socket")
    tcp_socket.stub!(:close)
    TCPSocket.stub!(:new).and_return(tcp_socket)
    
    @ssl_socket = mock("ssl_socket")
    @ssl_socket.stub!(:sync=)
    @ssl_socket.stub!(:connect)
    @ssl_socket.stub!(:write)
    @ssl_socket.stub!(:close)
    OpenSSL::SSL::SSLSocket.stub!(:new).and_return(@ssl_socket)
  end
  
  # TODO: This should really test SSLSocket.write
  it "should ping apple" do
    Apple.ping(@params)
  end
  
  it "should log deprecation on iphone ping" do
    Iphone.should_receive(
      :log
    ).once.with("DEPRECATION WARNING: 'iphone' is a deprecated device_type, use 'apple' instead")
    Iphone.ping(@params)
  end
  
  it "should compute apn_message" do
    expected = <<-eos
\000\000 \253\315\000g{"aps":{"vibrate":"5","badge":5,"sound":"hello.mp3","alert":"hello world"},"do_sync":["SampleAdapter"]}
eos
    Apple.apn_message(@params).should == expected.strip!
  end
  
  it "should compute apn_message with source array" do
    @params['sources'] << 'SimpleAdapter'
    expected = <<-eos
\000\000 \253\315\000w{"aps":{"vibrate":"5","badge":5,"sound":"hello.mp3","alert":"hello world"},"do_sync":["SampleAdapter","SimpleAdapter"]}
eos
    Apple.apn_message(@params).should == expected.strip!
  end
  
  it "should raise SocketError if socket fails" do
    error = 'socket error'
    @ssl_socket.stub!(:write).and_return { raise SocketError.new(error) }
    Apple.should_receive(:log).once.with("Error while sending ping: #{error}")
    lambda { Apple.ping(@params) }.should raise_error(SocketError,error)
  end
  
end