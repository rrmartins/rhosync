require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhosyncApiGetLicenseInfo" do
  it_should_behave_like "ApiHelper" do
    it "should get license info" do
      true.should == true
      post "/api/admin/get_license_info", {:api_token => @api_token}
      JSON.parse(last_response.body).should == {
        "available" => 9, 
        "issued" => "Fri Apr 23 17:20:13 -0700 2010", 
        "seats" => 10, 
        "rhosync_version" => "Version 1",
        "licensee" => "Rhomobile" }
    end
    
    it "should get custom_license info with deprecation warning" do
      true.should == true
      
      # this one for test purposes to make sure
      # that an old way custom REST API still works
      Rhosync::Server.api :custom_license_info do |params,user|
        {:rhosync_version => Rhosync.license.rhosync_version, 
         :licensee => Rhosync.license.licensee, 
         :seats => Rhosync.license.seats, 
         :issued => Rhosync.license.issued,
         :available => Rhosync.license.available }.to_json
      end
      
      post "/api/custom_license_info", {:api_token => @api_token}
      JSON.parse(last_response.body).should == {
        "available" => 9, 
        "issued" => "Fri Apr 23 17:20:13 -0700 2010", 
        "seats" => 10, 
        "rhosync_version" => "Version 1",
        "licensee" => "Rhomobile" }
    end
  end  
end