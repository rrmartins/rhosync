require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListUsers" do
  it_should_behave_like "ApiHelper"
  
  it "should list clients" do
    post "/api/list_clients", {:app_name => @appname, :api_token => @api_token,
      :user_id => @u_fields[:login]}
    res = JSON.parse(last_response.body)
    res.is_a?(Array).should == true
    res.size.should == 1
    res[0].is_a?(String) == true
    res[0].length.should == 32
  end
  
  it "should handle empty client's list" do
    @u.clients.delete(@c.id)
    post "/api/list_clients", {:app_name => @appname, :api_token => @api_token, 
      :user_id => @u_fields[:login]}
    JSON.parse(last_response.body).should == []    
  end
  
end