require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')


describe "DynamicAdapter" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    
    it "should return login when backend service defined" do
      stub_request(:post, "http://test.com/rhoconnect/authenticate").to_return(:body => "lucas")
      Rhosync.appserver = 'http://test.com'
      DynamicAdapter.authenticate('lucas','').should == 'lucas'
    end
    
    it "should query dynamic adapter service" do
      data = {'1'=>@product1} 
      stub_request(:post, "http://test.rhosync.com/rhoconnect/query").with(:headers => {'Content-Type' => 'application/json'}).to_return(:status => 200, :body => data.to_json)
      da = DynamicAdapter.new(@s2,nil,'http://test.rhosync.com')
      da.query.should == data
    end
    
    it "should create new object using dynamic adapter" do
      stub_request(:post, "http://test.rhosync.com/rhoconnect/create").with(:headers => {'Content-Type' => 'application/json'}).to_return(:body => {:id => 5})
      da = DynamicAdapter.new(@s2,nil,'http://test.rhosync.com')
      da.create(@product1).should == {:id => 5}
    end
    
    it "should update object using dynamic adapter" do
      data = {'id' => 2} 
      stub_request(:post, "http://test.rhosync.com/rhoconnect/update").with(:headers => {'Content-Type' => 'application/json'}).to_return(:body => {:id => 5})
      da = DynamicAdapter.new(@s2,nil,'http://test.rhosync.com')
      da.update(data).should == {:id => 5}
    end
    
    it "should delete object using dynamic adapter" do
      data = {'id' => 2}
      stub_request(:post, "http://test.rhosync.com/rhoconnect/delete").with(:headers => {'Content-Type' => 'application/json'}).to_return(:body => {:id => 5})
      da = DynamicAdapter.new(@s2,nil,'http://test.rhosync.com')
      da.delete(data).should == {:id => 5}
    end
    
    
  end
end