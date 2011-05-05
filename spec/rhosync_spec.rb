require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "Rhosync" do
  include TestHelpers    
  let(:test_app_name) { 'application' }  

  before(:each) do 
    Store.create
    Store.db.flushdb
  end
  
  it "should bootstrap Rhosync with block" do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = 'foo'
    end
    path = get_testapp_path
    File.expand_path(Rhosync.base_directory).should == path
    File.expand_path(Rhosync.app_directory).should == path
    File.expand_path(Rhosync.data_directory).should == File.join(path,'data')
    Rhosync.vendor_directory.should == 'foo'
    Rhosync.blackberry_bulk_sync.should == false
    Rhosync.bulk_sync_poll_interval.should == 3600
    Rhosync.environment.should == :test  
    Rhosync.stats.should == false
    App.is_exist?(test_app_name).should be_true
  end

  it "should bootstrap Rhosync with RHO_ENV provided" do
    ENV['RHO_ENV'] = 'production'
    Rhosync.bootstrap(get_testapp_path)
    Rhosync.environment.should == :production
    ENV.delete('RHO_ENV')
  end
  
  it "should bootstrap Rhosync with RACK_ENV provided" do
    env = ENV['RACK_ENV'].dup
    ENV['RACK_ENV'] = 'production'
    Rhosync.bootstrap(get_testapp_path)
    Rhosync.environment.should == :production
    ENV['RACK_ENV'] = env
  end
  
  it "should bootstrap with existing app" do
    app = App.create(:name => test_app_name)
    App.should_receive(:load).once.with(test_app_name).and_return(app)
    Rhosync.bootstrap(get_testapp_path)
  end

  it "should bootstrap app with no sources" do
    app = App.create(:name => test_app_name)
    Rhosync.stub!(:get_config).and_return(
      { Rhosync.environment.to_sym => { :licensefile => 'settings/license.key' } }
    )
    App.should_receive(:load).twice.with(test_app_name).and_return(app)
    Rhosync.bootstrap(get_testapp_path)
    App.load(test_app_name).sources.members.should == []
  end

  it "should exit if schema config exists" do
    config = Rhosync.get_config(get_testapp_path)
    config[:sources]['FixedSchemaAdapter'].merge!(
      'schema' => {'property' => 'foo'}
    )
    Rhosync.stub!(:get_config).and_return(config)
    Rhosync.should_receive(:log).once.with(
      "ERROR: 'schema' field in settings.yml is not supported anymore, please use source adapter schema method!"
    )
    lambda { Rhosync.bootstrap(get_testapp_path) }.should raise_error(SystemExit)
  end

  it "should add associations during bootstrap" do
    Rhosync.bootstrap(get_testapp_path)
    s = Source.load('SampleAdapter',{:app_id => test_app_name,:user_id => '*'})
    s.has_many.should == "FixedSchemaAdapter,brand"
  end
end