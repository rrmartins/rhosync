require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiPing" do
  it_should_behave_like "ApiHelper"
  
  it "should do ping synchronously" do
    params = {"user_id" => @u.id, "api_token" => @api_token,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    PingJob.should_receive(:perform).once.with(params)
    post "/api/ping", params
    last_response.should be_ok
  end
  
  it "should do ping asynchronously" do
    params = {"user_id" => @u.id, "api_token" => @api_token, 
      "async" => "true","sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    PingJob.should_receive(:enqueue).once.with(params)
    post "/api/ping", params
    last_response.should be_ok
  end
  
end