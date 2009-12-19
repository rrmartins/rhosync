require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiDeleteApp" do
  it_should_behave_like "ApiHelper"
  
  it "should update user successfully" do
    post "/api/update_user", :api_token => @api_token, :payload => {:login => 'admin',
      :password => '', :attributes => {:new_password => '123'} }
    last_response.should be_ok
    user = User.authenticate('admin','123')
    user.login.should == 'admin'
    user.admin.should == 1
  end
  
  it "should fail to update user with wrong attributes" do
    post "/api/update_user", :api_token => @api_token, :payload => {:login => 'admin',
      :password => '', :attributes => {:missingattrib => '123'} }
    last_response.status.should == 500
    last_response.body.match('undefined method').should_not be_nil
  end
  
  it "should fail to update user with wrong login/password" do
    post "/api/update_user", :api_token => @api_token, :payload => {:login => 'admin',
      :password => 'wrong', :attributes => {:new_password => '123'} }
    last_response.status.should == 500
    last_response.body.match("Unknown user/password").should_not be_nil
    User.authenticate('admin','123').should be_nil
  end
  
  it "should not update login attribute for user" do
    post "/api/update_user", :api_token => @api_token, :payload => {:login => 'admin',
      :password => '', :attributes => {:new_password => '123', :login => 'admin1'} }
    last_response.should be_ok
    user = User.authenticate('admin','123')
    user.login.should == 'admin'
    user.admin.should == 1
    User.is_exist?('admin1','login').should == false
  end
end