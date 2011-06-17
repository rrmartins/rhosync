require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiDeleteUser" do
  it_should_behave_like "ApiHelper" do 
    it "should delete user" do
      params = {:api_token => @api_token,
        :attributes => {:login => 'testuser1', :password => 'testpass1'}}
      post "/api/user/create_user", params
      last_response.should be_ok
      User.is_exist?(params[:attributes][:login]).should == true
      post "/api/user/delete_user", {:api_token => @api_token, 
        :user_id => params[:attributes][:login]}  
        last_response.should be_ok
      User.is_exist?(params[:attributes][:login]).should == false
      App.load(test_app_name).users.members.should == ["testuser"]
    end
  end  
end