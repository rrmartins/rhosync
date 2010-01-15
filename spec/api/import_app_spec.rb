require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiImportApp" do
  it_should_behave_like "ApiHelper"
  
  it "should return 422 with wrong api token" do
    @api_token = 'wrongtoken'
    upload_test_apps
    last_response.status.should == 422
    last_response.body.should == "No API token provided"
  end
  
  it "should upload zipfile and import app and sources" do   
    upload_test_apps
    
    App.is_exist?(@appname).should == true
    sources = App.load(@appname).sources.members.sort
    sources.should == ["SampleAdapter", "SimpleAdapter"]
    sources.each do |source|    
      Source.is_exist?(source).should == true
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
    upload_test_apps
    lambda { SourceAdapter.create(@s,nil).hello }.should raise_error(Exception)
    FileUtils.rm_rf File.join(File.dirname(__FILE__),'..','..','apps')
    @a.delete
    @appname = 'testapptwo'
    target = File.join(File.dirname(__FILE__),'..','apps',@appname)
    FileUtils.cp_r File.join(File.dirname(__FILE__),'..','testdata',@appname), target
    upload_test_apps
    SourceAdapter.create(@s,nil).hello.should == 'hello'
    FileUtils.rm_rf target
  end
end