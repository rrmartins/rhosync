require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiDeleteApp" do
  it_should_behave_like "ApiHelper"
  
  it "should delete aplication" do
    upload_test_apps
    sources = App.load(@appname).sources.members

    post "/api/delete_app", :app_name => @appname, :api_token => @api_token
    
    App.is_exist?(@appname).should == false
    sources.each do |source|    
      Source.is_exist?(source).should == false
    end
    File.exists?(File.join(File.dirname(__FILE__),'..','..','apps',@appname)).should == false
  end
end