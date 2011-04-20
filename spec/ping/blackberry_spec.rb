require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__), '..', 'support', 'shared_examples')

describe "Ping Blackberry" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => false do
    before do
      @params = {"user_id" => @u.id, "api_token" => @api_token,
        "sources" => [@s.name], "message" => 'hello world', 
        "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3',
        "device_pin" => @c.device_pin, "device_port" => @c.device_port}
      post = mock('post')
      post.stub!(:new).and_return(post)
      post.stub!(:body=)
      Net::HTTP::Post.stub!(:new).and_return(post)

      @http = mock('http')
      @http.stub!(:request)
      @http.stub!(:start).and_yield(@http)
      Net::HTTP.stub!(:new).and_return(@http)
    end

    it "should ping blackberry" do
      Blackberry.ping(@params)
    end

    it "should ping blackberry with connection error" do
      error = 'Connection refused'
      @http.stub!(:request).and_return { raise SocketError.new(error) }
      Blackberry.should_receive(:log).once.with("Error while sending ping: #{error}")
      lambda { Blackberry.ping(@params) }.should raise_error(SocketError,error)
    end

    it "should compute pap_message" do
      expected = <<PAP
--asdlfkjiurwghasf
Content-Type: application/xml; charset=UTF-8
  
<?xml version="1.0"?>
<!DOCTYPE pap PUBLIC "-//WAPFORUM//DTD PAP 2.0//EN" 
  "http://www.wapforum.org/DTD/pap_2.0.dtd" 
  [<?wap-pap-ver supported-versions="2.0"?>]>
<pap>
<push-message push-id="pushID:RAND_ID" ppg-notify-requested-to="http://localhost:7778">

<address address-value="WAPPUSH=0%3A100/TYPE=USER@rim.net"/>
<quality-of-service delivery-method="preferconfirmed"/>
</push-message>
</pap>
--asdlfkjiurwghasf
Content-Type: text/plain

do_sync=SampleAdapter
alert=hello world
vibrate=5
sound=hello.mp3
--asdlfkjiurwghasf-- 
PAP
      actual = Blackberry.pap_message(@params).gsub!(/pushID\:\d+/,'pushID:RAND_ID')
      actual.gsub!(/\r|\n|\s/,"").should == expected.gsub!(/\r|\n|\s/,"")
    end
  end        
end