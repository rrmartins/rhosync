require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetApiToken" do
  it_should_behave_like "ApiHelper"
  
  it "should get token string" do
    post "/login", :login => 'admin',:password => ''
    post "/api/get_api_token"
    last_response.body.should == @api_token
  end
  
end