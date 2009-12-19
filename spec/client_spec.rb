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

  it "should delete client and all associated documents" do
    clientdoc = Document.new('cd',@a.id,@u.login,@c.id,@s.name)    
    @a.store.put_data(@cdoc.get_key,@data)    
    @a.store.put_data(clientdoc.get_key,@data)
    @a.store.put_data(clientdoc.get_page_dockey,@data)
    @a.store.put_value(clientdoc.get_page_token_dockey,"@data")
    @a.store.put_data(clientdoc.get_search_dockey,@data)
    @a.store.put_data(clientdoc.get_search_errors_dockey,@data)
    @a.store.put_data(clientdoc.get_delete_page_dockey,@data)
    @a.store.put_data(clientdoc.get_delete_errors_dockey,@data)
    @a.store.put_data(clientdoc.get_update_dockey,@data)
    @a.store.put_data(clientdoc.get_update_errors_dockey,@data)
    @a.store.put_data(clientdoc.get_create_dockey,@data)
    @a.store.put_data(clientdoc.get_create_errors_dockey,@data)
    @a.store.put_data(clientdoc.get_create_links_dockey,@data)
    @a.store.put_data(clientdoc.get_source_errors_dockey,@data)
    
    @c.delete
    
    @a.store.get_data(clientdoc.get_key).should == {}
    @a.store.get_data(clientdoc.get_page_dockey).should == {}
    @a.store.get_value(clientdoc.get_page_token_dockey).should == nil
    @a.store.get_data(clientdoc.get_search_dockey).should == {}
    @a.store.get_data(clientdoc.get_search_errors_dockey).should == {}
    @a.store.get_data(clientdoc.get_delete_page_dockey).should == {}
    @a.store.get_data(clientdoc.get_delete_errors_dockey).should == {}
    @a.store.get_data(clientdoc.get_update_dockey).should == {}
    @a.store.get_data(clientdoc.get_update_errors_dockey).should == {}
    @a.store.get_data(clientdoc.get_create_dockey).should == {}
    @a.store.get_data(clientdoc.get_create_errors_dockey).should == {}
    @a.store.get_data(clientdoc.get_create_links_dockey).should == {}
    @a.store.get_data(clientdoc.get_source_errors_dockey).should == {}
    @a.store.get_value(Document.get_datasize_dockey(clientdoc.get_key)).should == nil    
    @a.store.get_data(@cdoc.get_key).should == @data    
  end
end