require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiCreateUser" do
  it_should_behave_like "ApiHelper"
  
  it "should create user as admin" do
    params = { :app_name => @appname, :api_token => @api_token,
      :login => 'testuser1', :password => 'testpass1' }
    upload_test_apps
    post "/api/create_user", params
    last_response.should be_ok
    User.with_key(params[:login]).login.should == params[:login]
    User.authenticate(params[:login],
      params[:password]).login.should == params[:login]
    @a.users.members.should == [params[:login]]
  end
end