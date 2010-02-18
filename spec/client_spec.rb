require File.join(File.dirname(__FILE__),'spec_helper')

describe "Client" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create client with fields" do
    @c.id.length.should == 32
    @c.device_type.should == @c_fields[:device_type]
  end
  
  it "should create client with user_id" do
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
  
  it "should raise ArgumentError if source_name is not provided" do
    lambda { Client.create(@c_fields,{}) }.should
      raise_error(ArgumentError, "Missing required field 'source_name'")
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
end