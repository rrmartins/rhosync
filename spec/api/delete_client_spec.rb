require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiDeleteUser" do
  it_should_behave_like "ApiHelper"
  
  it "should delete client" do
    post "/api/delete_client", {:app_name => @appname, :api_token => @api_token,
      :user_id => @u_fields[:login], :client_id => @c.id}
    last_response.should be_ok
    Client.is_exist?(@c.id).should == false
    User.load(@u_fields[:login]).clients.members.should == []
  end
end