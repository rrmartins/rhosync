require File.join(File.dirname(__FILE__),'spec_helper')

describe "License" do
#  it_should_behave_like "SpecBootstrapHelper"
  before(:all) do # "TestappHelper"
    @test_app_name = 'application'
  end
  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end
    
  #it_should_behave_like "SourceAdapterHelper"
  #   it_should_behave_like "RhosyncDataHelper"
  before(:each) do # "RhosyncHelper"
    Store.create
    Store.db.flushdb
  end
  before(:each) do 
    @source = 'Product'
    @user_id = 5
    @client_id = 1
    
    @product1 = {
      'name' => 'iPhone',
      'brand' => 'Apple',
      'price' => '199.99'
    }
    
    @product2 = {
      'name' => 'G2',
      'brand' => 'Android',
      'price' => '99.99'
    }

    @product3 = {
      'name' => 'Fuze',
      'brand' => 'HTC',
      'price' => '299.99'
    }
    
    @product4 = {
      'name' => 'Droid',
      'brand' => 'Android',
      'price' => '249.99'
    }
    
    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end
  #   it_should_behave_like "DBObjectsHelper"
  before(:each) do
    @a_fields = { :name => @test_app_name }
    # @a = App.create(@a_fields)
    @a = (App.load(@test_app_name) || App.create(@a_fields))
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'Apple',
      :device_pin => 'abcd',
      :device_port => '3333',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.load(@s_fields[:name],@s_params)
    @s = Source.create(@s_fields,@s_params) if @s.nil?
    @s1 = Source.load('FixedSchemaAdapter',@s_params)
    @s1 = Source.create({:name => 'FixedSchemaAdapter'},@s_params) if @s1.nil?
    config = Rhosync.source_config["sources"]['FixedSchemaAdapter']
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources.members)
    @a.users << @u.id
  end

  
  before(:each) do
    Store.put_value(License::CLIENT_DOCKEY,nil)
  end
  
  it "should decrypt license" do
    license = License.new
    license.rhosync_version.should == 'Version 1'
    license.licensee.should == 'Rhomobile'
    license.seats.should == 10
    license.issued.should == 'Fri Apr 23 17:20:13 -0700 2010'
  end
  
  it "should raise exception on license load error" do
    Rhosync.stub!(:get_config).and_return({Rhosync.environment.to_sym => {}})
    lambda { License.new }.should raise_error(LicenseException, "Error verifying license.")
  end
  
  it "should verify # of seats before adding" do
    License.new.check_and_use_seat
    Store.get_value(License::CLIENT_DOCKEY).to_i.should == 1
  end
   
  it "should raise exception when seats are exceeded" do
    Store.put_value(License::CLIENT_DOCKEY,10)
    lambda { License.new.check_and_use_seat }.should raise_error(
      LicenseSeatsExceededException, "WARNING: Maximum # of devices exceeded for this license."
    )
  end
  
  it "should free license seat" do
    Store.put_value(License::CLIENT_DOCKEY,5)
    License.new.free_seat
    Store.get_value(License::CLIENT_DOCKEY).to_i.should == 4
  end

  it "should get # of available seats" do
    license = License.new
    license.check_and_use_seat
    license.available.should == 9
  end
  
  it "should use RHOSYNC_LICENSE env var" do
    ENV['RHOSYNC_LICENSE'] = 'b749cbe6e029400e688360468624388e2cb7f6a1e72c91d4686a1b8c9d37b72c3e1872ec9f369d481220e10759c18e16'
    license = License.new
    license.licensee.should == 'Rhohub'
    license.seats.should == 5
    license.issued.should == 'Tue Aug 10 16:14:24 -0700 2010'
    ENV.delete('RHOSYNC_LICENSE')
  end

end