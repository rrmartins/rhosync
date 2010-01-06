require File.join(File.dirname(__FILE__),'spec_helper')

describe "Sync Server States" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do    
    @cs = ClientSync.new(@s,@c,2)
  end
  
  # describe "do initial sync" do
  #   it "should sync with backend, setup masterdoc, clientdoc, and page documents" do
  #     expected = {'1'=>@product1,'2'=>@product2}
  #     set_test_data(@s.document.get_key,@data)
  #     @a.store.put_value(@s.document.get_datasize_dockey,@data.size)
  #     @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
  #       {"token"=>@s.app.store.get_value(@cs.clientdoc.get_page_token_dockey)}, 
  #       {"count"=>2}, {"progress_count"=>0},{"total_count"=>3},{'insert'=>expected}]
  #     verify_result(@s.document.get_key => @data,
  #       @cs.clientdoc.get_page_dockey => expected,
  #       @cs.clientdoc.get_key => expected)
  #   end
  # end
  
  describe "client creates objects" do
    # it "should send link if source adapter create returns object id" do
    #   exp_links = {'temp1'=>{'l'=>'1'}}
    #   result = {'1'=>@product1}
    #   set_test_data(@s.document.get_key,result)
    #   @a.store.put_value(@s.document.get_datasize_dockey,result.size)
    #   @cs.receive_cud({'create'=>{'temp1'=>@product1}})
    #   verify_result(@cs.clientdoc.get_create_links_dockey => exp_links,
    #     @s.document.get_key => result)
    #   @a.store.delete_data(@s.document.get_key,{"1"=>{"rhomobile.rhoclient"=>"1"}})
    #   @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
    #     {"token"=>@s.app.store.get_value(@cs.clientdoc.get_page_token_dockey)}, 
    #     {"count"=>0}, {"progress_count"=>1},{"total_count"=>1},{'links'=>exp_links}]
    #   result['1'].delete('rhomobile.rhoclient')
    #   verify_result(@cs.clientdoc.get_page_dockey => {},
    #     @cs.clientdoc.get_key => result)
    # end
    
    it "should create object and send link to client" do
      @product1['link'] = 'temp1'
      params = {'create'=>{'1'=>@product1}}
      backend_data = {'backend_id'=>@product1}
      set_state('test_db_storage' => backend_data)
      @cs.receive_cud(params)
      verify_result(@cs.clientdoc.get_create_dockey => {},
        @cs.clientdoc.get_key => backend_data,
        @s.document.get_create_dockey => [],
        @cs.clientdoc.get_create_links_dockey => {'1'=>{'l'=>'backend_id'}},
        @s.document.get_key => backend_data)
    end
  end
  
  describe "client deletes objects" do
    it "should delete object" do
      params = {'delete'=>{'1'=>@product1}}
      set_state(@cs.clientdoc.get_key => {'1'=>@product1},
        @s.document.get_key => {'1'=>@product1})
      @cs.receive_cud(params)
      verify_result(@cs.clientdoc.get_delete_dockey => {},
        @cs.clientdoc.get_key => {},
        @s.document.get_delete_dockey => [],
        @s.document.get_key => {},
        @cs.clientdoc.get_delete_page_dockey => {},
        'test_delete_storage' => {'1'=>@product1})
    end
  end
end