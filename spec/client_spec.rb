require File.join(File.dirname(__FILE__),'spec_helper')

describe "Client" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create client with fields" do
    @c.id.should == 1
    @c.device_type.should == @c_fields[:device_type]
  end
  
  it "should create client with user_id" do
    @c.id.should == 1
    @c.user_id.should == @c_fields[:user_id] 
  end
  
  it "should raise exception if user_id is not specified" do
    lambda { Client.create() }.should raise_error(InvalidClientUserIdError, 'Invalid User Id Argument')    
  end

  it "should raise exception if app_id is not specified" do
    lambda { Client.create(:user_id => 'testuser') }.should raise_error(InvalidClientAppIdError, 'Invalid App Id Argument')    
  end
  
  it "should raise exception if source_name is nil" do
    @c.source_name = nil
    lambda { @c.doc_suffix('foo') }.should raise_error(InvalidSourceNameError, 'Invalid Source Name For Client')
  end

  it "should delete client and all associated documents" do
    set_state(@c.docname(:cd) => @data)    
    
    @c.delete
    
    verify_result(@c.docname(:cd) => {})
  end
end