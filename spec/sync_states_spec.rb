require File.join(File.dirname(__FILE__),'spec_helper')

describe "Sync Server States" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "StorageStateHelper"
  
  before(:each) do    
    @cs = ClientSync.new(@s,@c,2)
  end
  
  describe "do initial sync" do
    it "should sync with backend, setup masterdoc, clientdoc, and page documents" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_test_data(@s.document.get_key,@data)
      @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
        {"token"=>@s.app.store.get_value(@cs.clientdoc.get_page_token_dockey)}, 
        {"count"=>2}, {"progress_count"=>2},{"total_count"=>3},{'insert'=>expected}]
      verify_result(@s.document.get_key => @data,
        @cs.clientdoc.get_page_dockey => expected,
        @cs.clientdoc.get_key => expected)
    end
  end
  
  def verify_result_hash()
  end
  
  describe "client creates objects" do
    it "should send link if source adapter create returns object id" do
      exp_links = {'temp1'=>{'l'=>'1'}}
      result = {'1'=>@product1}
      params = {'create'=>{'temp1'=>@product1}}
      set_test_data(@s.document.get_key,result)
      @cs.receive_cud(params)
      verify_result(@cs.clientdoc.get_create_links_dockey => exp_links,
        @s.document.get_key => result)
      @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
        {"token"=>@s.app.store.get_value(@cs.clientdoc.get_page_token_dockey)}, 
        {"count"=>1}, {"progress_count"=>1},{"total_count"=>1},{'insert'=>result,'links'=>exp_links}]
      verify_result(@cs.clientdoc.get_page_dockey => result)
    end
  end
end