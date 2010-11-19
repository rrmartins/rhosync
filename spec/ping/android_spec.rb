require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Android" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
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
