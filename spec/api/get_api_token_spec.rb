require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetApiToken" do
  it_should_behave_like "ApiHelper"
  
  it "should get token string" do
    post "/login", :login => 'admin',:password => ''
    post "/api/get_api_token"
    last_response.body.should == @api_token
  end
  
  it "should return 422 if no token provided" do
    params = {:app_name => @appname, :attributes => 
      {:login => 'testuser1', :password => 'testpass1'}}
    post "/api/create_user", params
    last_response.status.should == 422
  end
end