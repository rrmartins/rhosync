require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListUsers" do
  it_should_behave_like "ApiHelper" do
    it "should list users" do
      params = {:api_token => @api_token,
        :attributes => {:login => 'testuser1', :password => 'testpass1'}}
      post "/api/user/create_user", params
      last_response.should be_ok
      post "/api/user/list_users", {:api_token => @api_token}
      JSON.parse(last_response.body).should == ["testuser", "testuser1"]
    end

    it "should handle empty user's list" do
      @a.delete; @a = App.create(@a_fields)
      post "/api/user/list_users", {:api_token => @api_token}
      JSON.parse(last_response.body).should == []    
    end
    
    it "should show the deprecation warning on /api/list users" do
      params = {:api_token => @api_token,
        :attributes => {:login => 'testuser1', :password => 'testpass1'}}
      post "/api/user/create_user", params
      last_response.should be_ok
      post "/api/list_users", {:api_token => @api_token}
      JSON.parse(last_response.body).should == ["testuser", "testuser1"]
      last_response.headers['Warning'].index('deprecated').should_not == nil
    end
  end  
end