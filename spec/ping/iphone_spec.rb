require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Iphone" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
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
  it "should ping iphone" do
    Iphone.ping(@params)
  end
  
  it "should compute apn_message" do
    expected = <<-eos
\000\000 \253\315\000g{"aps":{"vibrate":"5","badge":5,"sound":"hello.mp3","alert":"hello world"},"do_sync":["SampleAdapter"]}
eos
    Iphone.apn_message(@params).should == expected.strip!
  end
  
  it "should raise SocketError if socket fails" do
    error = 'socket error'
    @ssl_socket.stub!(:write).and_return { raise SocketError.new(error) }
    Logger.should_receive(:error).once.with("Error while sending ping: #{error}")
    lambda { Iphone.ping(@params) }.should raise_error(SocketError,error)
  end
  
end