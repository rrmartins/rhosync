require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetApiToken" do
  it_should_behave_like "ApiHelper" do
    it "should login and receive the token string" do
      post "/api/admin/login", :login => 'rhoadmin',:password => ''
      last_response.body.should == @api_token
    end
    
    it "should get deprecation warning for get_api_token method" do
      post "/api/admin/login", :login => 'rhoadmin',:password => ''
      post "/api/admin/get_api_token"
      last_response.body.should == @api_token
      last_response.headers['Warning'].index('deprecated').should_not == nil
    end

    it "should fail to login and get token if user is not rhoadmin" do
      post "/api/admin/login", :login => @u_fields[:login],:password => 'testpass'
      last_response.status.should == 422    
      last_response.body.should == 'Invalid/missing API user'
    end  

    it "should return 422 if no token provided" do
      params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
      post "/api/user/create_user", params
      last_response.status.should == 422
    end
  end  
end