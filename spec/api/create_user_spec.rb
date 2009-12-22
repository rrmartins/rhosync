require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiCreateUser" do
  it_should_behave_like "ApiHelper"
  
  it "should create user as admin" do
    attributes = { :login => 'testuser1', :password => 'testpass1' }
    upload_test_apps
    post "/api/create_user", :app_name => @appname, :api_token => @api_token,
      :attributes => attributes
    last_response.should be_ok
    User.with_key('testuser1').login.should == attributes[:login]
    User.authenticate(attributes[:login],
      attributes[:password]).login.should == attributes[:login]
    @a.users.members.should == ['testuser1']
  end
end