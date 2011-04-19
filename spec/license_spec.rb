require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "License" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => false do
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

end