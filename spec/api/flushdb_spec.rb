require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiUploadFile" do
  it_should_behave_like "ApiHelper"
  
  it "should flushdb and re-create admin user" do
    upload_test_apps
    post "/api/flushdb", :api_token => @api_token
    App.is_exist?(@appname,'name').should == false
    User.authenticate('admin','').should_not be_nil
  end
  
end