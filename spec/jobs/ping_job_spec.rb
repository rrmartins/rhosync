require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__), '..', 'support', 'shared_examples')

describe "PingJob" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
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
end