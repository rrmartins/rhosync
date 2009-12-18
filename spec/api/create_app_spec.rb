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
    entries.sort.should == ["config.yml", "rhotestapp.rb", "sources", "vendor"]
  end
  
  it "should add vendor libs to load path" do
    upload_test_apps
    require 'mygem'
    Mygem::Mygem.version.should == '0.1.0'
  end
  
  it "should add application class to load path" do
    upload_test_apps
    Rhotestapp.authenticate('','',{}).should == true
  end
  
  it "should re-load SampleAdapter on second create" do
    @sa = SourceAdapter.create(@s,nil)
    lambda { @sa.hello }.should raise_error(Exception)
    @appname = 'testapptwo'
    upload_test_apps
    SourceAdapter.create(@s,nil).hello.should == 'hello'
  end
end