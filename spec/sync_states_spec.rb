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
  #     set_test_data(@s.docname(:md),@data)
  #     Store.put_value(@s.docname(:md_size),@data.size)
  #     @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
  #       {"token"=>@c.get_value(:page_token)}, 
  #       {"count"=>2}, {"progress_count"=>0},{"total_count"=>3},{'insert'=>expected}]
  #     verify_result(@s.docname(:md) => @data,
  #       @cs.client.docname(:page) => expected,
  #       @cs.client.docname(:cd) => expected)
  #   end
  # end
  
  describe "client creates objects" do
    # it "should send link if source adapter create returns object id" do
    #   exp_links = {'temp1'=>{'l'=>'1'}}
    #   result = {'1'=>@product1}
    #   set_test_data(@s.docname(:md),result)
    #   Store.put_value(@s.docname(:md_size),result.size)
    #   @cs.receive_cud({'create'=>{'temp1'=>@product1}})
    #   verify_result(@c.docname(:create_links) => exp_links,
    #     @s.docname(:md) => result)
    #   Store.delete_data(@s.docname(:md),{"1"=>{"rhomobile.rhoclient"=>"1"}})
    #   @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
    #     {"token"=>@c.get_value(:page_token)}, 
    #     {"count"=>0}, {"progress_count"=>1},{"total_count"=>1},{'links'=>exp_links}]
    #   result['1'].delete('rhomobile.rhoclient')
    #   verify_result(@cs.client.docname(:page) => {},
    #     @cs.client.docname(:cd) => result)
    # end
    
    it "should create object and create link for client" do
      @product1['link'] = 'temp1'
      params = {'create'=>{'1'=>@product1}}
      backend_data = {'backend_id'=>@product1}
      set_state(@cs.client.docname(:cd_size) => 0,
        @s.docname(:md_size) => 0)
      @s.read_state.refresh_time = Time.now.to_i + 3600
      @cs.receive_cud(params)
      verify_result(@c.docname(:create) => {},
        @c.docname(:cd_size) => "1",
        @s.docname(:md_size) => "1",
        @c.docname(:cd) => backend_data,
        @c.docname(:create_links) => {'1'=>{'l'=>'backend_id'}},
        @s.docname(:md) => backend_data)
    end
    
    it "should create object and send link to client" do
      @product1['link'] = 'temp1'
      params = {'create'=>{'1'=>@product1}}
      backend_data = {'backend_id'=>@product1}
      set_state(@cs.client.docname(:cd_size) => 0,
        @s.docname(:md_size) => 0)
      @s.read_state.refresh_time = Time.now.to_i + 3600
      @cs.receive_cud(params)
      verify_result(@c.docname(:create) => {},
        @c.docname(:cd_size) => "1",
        @s.docname(:md_size) => "1",
        @c.docname(:cd) => backend_data,
        @c.docname(:create_links) => {'1'=>{'l'=>'backend_id'}},
        @s.docname(:md) => backend_data)
      res = @cs.send_cud
      res.should == [{"version"=>3}, {"token"=>res[1]['token']}, 
        {"count"=>0}, {"progress_count"=>1}, {"total_count"=>1}, 
        {"links"=> {'1'=>{'l'=>'backend_id'}}}]
      
    end
  end
  
  describe "client deletes objects" do
    it "should delete object" do
      params = {'delete'=>{'1'=>@product1}}
      data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
      expected = {'2'=>@product2,'3'=>@product3}
      set_state(@cs.client.docname(:cd) => data,
        @cs.client.docname(:cd_size) => data.size,
        @s.docname(:md) => data,
        @s.docname(:md_size) => data.size)
      @s.read_state.refresh_time = Time.now.to_i + 3600
      @cs.receive_cud(params)
      verify_result(@cs.client.docname(:delete) => {},
        @cs.client.docname(:cd) => expected,
        @s.docname(:md) => expected,
        @cs.client.docname(:delete_page) => {},
        @cs.client.docname(:cd_size) => "2",
        @s.docname(:md_size) => "2",
        'test_delete_storage' => {'1'=>@product1})
    end
  end
end