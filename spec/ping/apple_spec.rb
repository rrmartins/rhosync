require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__), '..', 'support', 'shared_examples')

describe "Ping Apple" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => false do
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
      expected_hash = {
        "aps"=>{"vibrate"=>"5", "badge"=>5, "alert"=>"hello world", "sound"=>"hello.mp3"}, 
        "do_sync"=>["SampleAdapter"] 
      }
      apn_message = Apple.apn_message(@params)
      apn_message.start_with?("\000\000 \253\315\000g").should be_true 
      JSON.parse(apn_message.sub("\000\000 \253\315\000g","")).should ==  expected_hash
    end

    it "should compute apn_message with source array" do
      @params['sources'] << 'SimpleAdapter'
      expected_hash = {
        "aps"=>{"vibrate"=>"5", "badge"=>5, "alert"=>"hello world", "sound"=>"hello.mp3"}, 
        "do_sync"=>["SampleAdapter", "SimpleAdapter"] 
      }
      apn_message = Apple.apn_message(@params)
      apn_message.start_with?("\000\000 \253\315\000w").should be_true 
      JSON.parse(apn_message.sub("\000\000 \253\315\000w","")).should ==  expected_hash
    end

    it "should raise SocketError if socket fails" do
      error = 'socket error'
      @ssl_socket.stub!(:write).and_return { raise SocketError.new(error) }
      Apple.should_receive(:log).once.with("Error while sending ping: #{error}")
      lambda { Apple.ping(@params) }.should raise_error(SocketError,error)
    end
  end  
end