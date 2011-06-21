require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhosyncApiUpdateUser" do
  it_should_behave_like "ApiHelper" do 
    it "should update user successfully" do
      post "/api/user/update_user", :api_token => @api_token, 
        :attributes => {:new_password => '123'}
      last_response.should be_ok
      user = User.authenticate('rhoadmin','123')
      user.login.should == 'rhoadmin'
      user.admin.should == 1
    end

    it "should fail to update user with wrong attributes" do
      post "/api/user/update_user", :api_token => @api_token,
        :attributes => {:missingattrib => '123'}
      last_response.status.should == 500
      last_response.body.match('undefined method').should_not be_nil
    end

    it "should not update login attribute for user" do
      post "/api/user/update_user", :api_token => @api_token, 
        :attributes => {:new_password => '123', :login => 'admin1'}
      last_response.should be_ok
      user = User.authenticate('rhoadmin','123')
      user.login.should == 'rhoadmin'
      user.admin.should == 1
      User.is_exist?('admin1').should == false
    end
  end
end