require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhosyncApiDeleteUser" do
  it_should_behave_like "ApiHelper" do 
    it "should delete user" do
      params = {:api_token => @api_token,
        :attributes => {:login => 'testuser1', :password => 'testpass1'}}
      post "/api/user/create_user", params
      last_response.should be_ok
      User.is_exist?(params[:attributes][:login]).should == true
      
      #set up two users with data for the same source
      params2 = {:app_id => APP_NAME,:user_id => 'testuser1'}
      params3 = {:app_id => APP_NAME,:user_id => 'testuser'}
      s  = Source.load('SampleAdapter', params2)
      s2 = Source.load('SampleAdapter', params3)
      set_state(s.docname(:delete) => {'4'=>@product4})
      set_state(s2.docname(:delete) => {'4'=>@product4})
      verify_result(s.docname(:delete) => {'4'=>@product4})
      verify_result(s2.docname(:delete) => {'4'=>@product4})
      
      
      post "/api/user/delete_user", {:api_token => @api_token, :user_id => params[:attributes][:login]}  
      last_response.should be_ok
      verify_result(s.docname(:delete) => {})
      verify_result(s2.docname(:delete) => {'4'=>@product4})
      
      User.is_exist?(params[:attributes][:login]).should == false
      App.load(test_app_name).users.members.should == ["testuser"]
    end
  end  
end