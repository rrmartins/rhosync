require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListUsers" do
  it_should_behave_like "ApiHelper"
  
  it "should list users" do
    params = {:app_name => @appname, :api_token => @api_token,
      :attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/api/create_user", params
    last_response.should be_ok
    post "/api/list_users", {:app_name => @appname, :api_token => @api_token}
    JSON.parse(last_response.body).should == ["testuser", "testuser1"]
  end
  
  it "should handle empty user's list" do
    @a.delete; @a = App.create(@a_fields)
    post "/api/list_users", {:app_name => @appname, :api_token => @api_token}
    JSON.parse(last_response.body).should == []    
  end
  
end