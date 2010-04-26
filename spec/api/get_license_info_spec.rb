require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetLicenseInfo" do
  it_should_behave_like "ApiHelper"
  
  it "should get license info" do
    true.should == true
    post "/api/get_license_info", {:api_token => @api_token}
    JSON.parse(last_response.body).should == {
      "available" => 9, 
      "issued" => "Fri Apr 23 17:20:13 -0700 2010", 
      "seats" => 10, 
      "rhosync_version" => "Version 1",
      "licensee" => "Rhomobile" }
  end
end