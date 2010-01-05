require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListApps" do
  it_should_behave_like "ApiHelper"
  
  it "should list aplications" do
    upload_test_apps
    post "/api/create_user", {:app_name => @appname, :api_token => @api_token,
      :attributes => {:login => 'testuser', :password => 'testpass'}}
    post "/api/list_apps", :api_token => @api_token
    
    last_response.should be_ok
    resp = JSON.parse(last_response.body)
    resp[0]['sources'].sort!
    resp.should == [{"name"=>"rhotestapp", 
      "sources"=>["SampleAdapter", "SimpleAdapter"], "users"=>["testuser"]}]
  end
end