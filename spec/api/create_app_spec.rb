require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiCreateApp" do
  it_should_behave_like "ApiHelper"
  
  it "should upload zipfile and create app and sources" do   
    upload_test_apps
    
    App.is_exist?(@appname,'name').should == true
    sources = App.with_key(@appname).sources.members.sort
    sources.should == ["SampleAdapter", "SimpleAdapter"]
    sources.each do |source|    
      Source.is_exist?(source,'name').should == true
    end
    target = File.join(File.dirname(__FILE__),'..','..','apps',@appname)
    entries = Dir.entries(target)
    entries.reject! {|entry| entry == '.' || entry == '..'}
    entries.sort.should == ["config.yml", "sources", "vendor"]
    FileUtils.rm_rf File.join(File.dirname(__FILE__),'..','..','apps')
  end
end