require File.join(File.dirname(__FILE__),'spec_helper')

describe "Rhosync" do
  it "should bootstrap Rhosync with no basedir" do
    Rhosync.bootstrap
    path = File.expand_path(File.join(File.dirname(__FILE__),'..'))
    File.expand_path(Rhosync.base_directory).should == path
    File.expand_path(Rhosync.app_directory).should == File.join(path,'apps')
    File.expand_path(Rhosync.data_directory).should == File.join(path,'data')
    File.expand_path(Rhosync.vendor_directory).should == File.join(path,'vendor')
    Rhosync.blackberry_bulk_sync.should == false
    Rhosync.environment.should == :development  
  end
  
  it "should bootstrap Rhosync with basedir provided" do
    path = File.expand_path(File.join(File.dirname(__FILE__)))
    Rhosync.bootstrap(path)
    File.expand_path(Rhosync.base_directory).should == path
    File.expand_path(Rhosync.app_directory).should == File.join(path,'apps')
    File.expand_path(Rhosync.data_directory).should == File.join(path,'data')
    File.expand_path(Rhosync.vendor_directory).should == File.join(path,'vendor')
    Rhosync.blackberry_bulk_sync.should == false
    Rhosync.environment.should == :development
  end
  
  it "should bootstrap Rhosync with RHO_ENV provided" do
    ENV['RHO_ENV'] = 'production'
    Rhosync.bootstrap
    Rhosync.environment.should == :production
    ENV.delete('RHO_ENV')
  end
end