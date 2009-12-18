require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiDeleteApp" do
  it_should_behave_like "ApiHelper"
  
  it "should delete aplication" do
    upload_test_apps
    sources = App.with_key(@appname).sources.members.sort
    sources.should == ["SampleAdapter", "SimpleAdapter"]

    post "/api/#{@appname}/delete_app", :api_token => @api_token
    
    App.is_exist?(@appname,'name').should == false
    sources.each do |source|    
      Source.is_exist?(source,'name').should == false
    end
    File.exists?(File.join(File.dirname(__FILE__),'..','..','apps',@appname)).should == false
  end
end