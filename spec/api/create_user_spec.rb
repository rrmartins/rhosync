require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiCreateUser" do
  it_should_behave_like "ApiHelper"
  
  it "should create user as admin" do
    params = {:app_name => @appname, :api_token => @api_token,
      :attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/api/create_user", params
    last_response.should be_ok
    User.load(params[:attributes][:login]).login.should == params[:attributes][:login]
    User.authenticate(params[:attributes][:login],
      params[:attributes][:password]).login.should == params[:attributes][:login]
    @a.users.members.sort.should == [@u.login, params[:attributes][:login]]
  end
end