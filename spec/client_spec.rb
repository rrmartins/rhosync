require File.join(File.dirname(__FILE__),'spec_helper')

STATS_RECORD_RESOLUTION = 2 unless defined? STATS_RECORD_RESOLUTION
STATS_RECORD_SIZE = 8 unless defined? STATS_RECORD_SIZE

describe "Client" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create client with fields" do
    @c.id.length.should == 32
    @c.device_type.should == @c_fields[:device_type]
  end
  
  it "should update_fields for a client" do
    @c.update_fields({:device_type => 'android',:device_port => 100})
    @c.device_type.should == 'android'
    @c.device_port.should == '100'
  end
  
  it "should create client with user_id" do
    Store.get_value('client:count').should == "1"
    @c.id.length.should == 32
    @c.user_id.should == @c_fields[:user_id]
    @u.clients.members.should == [@c.id]
  end
  
  it "should raise exception if source_name is nil" do
    @c.source_name = nil
    lambda { 
      @c.doc_suffix('foo') 
    }.should raise_error(InvalidSourceNameError, 'Invalid Source Name For Client')
  end
  
  it "should raise exception if license seats exceeded" do
    Store.put_value(License::CLIENT_DOCKEY,100)
    lambda { Client.create(@c_fields,{}) }.should raise_error(
      LicenseSeatsExceededException, "WARNING: Maximum # of devices exceeded for this license."
    )
  end
  
  it "should free seat when client is deleted" do
    current = Store.get_value(License::CLIENT_DOCKEY).to_i
    @c.delete
    Store.get_value('client:count').should == '0'
    Store.get_value(License::CLIENT_DOCKEY).to_i.should == current - 1
  end

  it "should delete client and all associated documents" do
    docname = @c.docname(:cd)
    set_state(docname => @data)    
    @c.delete
    verify_result(docname => {})
  end
  
  it "should create cd as masterdoc clone" do
    set_state(@s.docname(:md_copy) => @data,
      @c.docname(:cd) => {'foo' => {'bar' => 'abc'}})
    @c.update_clientdoc([@s_fields[:name]])
    verify_result(@c.docname(:cd) => @data,
      @s.docname(:md_copy) => @data)
  end
  
  it "should update client schema_sha1" do
    set_state(@s.docname(:md_copy) => @data, 
      @s.docname(:schema_sha1) => 'foobar',
      @c.docname(:cd) => {'foo' => {'bar' => 'abc'}})
    @c.update_clientdoc([@s_fields[:name]])
    verify_result(@c.docname(:cd) => @data,
      @s.docname(:md_copy) => @data,
      @c.docname(:schema_sha1) => 'foobar')  
  end
  
  describe "Client Stats" do
    
    before(:each) do
      Rhosync::Stats::Record.reset('clients')
    end
    
    after(:each) do
      Rhosync::Stats::Record.reset('clients')
    end
    
    after(:all) do
      Store.flash_data('stat:clients*')
    end
  
    it "should increment clients stats on create" do
      Time.stub!(:now).and_return(10)
      Rhosync.stats = true
      Client.create(@c_fields,{:source_name => @s_fields[:name]})
      Rhosync::Stats::Record.range('clients',0,-1).should == ["2:10"]
      Store.get_value('client:count').should == "2"
      Rhosync.stats = false
    end
  
    it "should decrement clients stats on delete" do
      Time.stub!(:now).and_return(10)
      Rhosync.stats = true
      c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
      Rhosync::Stats::Record.range('clients',0,-1).should == ["2:10"]
      c.delete
      Rhosync::Stats::Record.range('clients',0,-1).should == ["1:10"]
      Store.get_value('client:count').should == "1"
      Rhosync.stats = false
    end
  end
end