require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "Sync Server States" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    before(:each) do   
      @s = Source.load(@s_fields[:name],@s_params) 
      @cs = ClientSync.new(@s,@c,2)
    end

    describe "client creates objects" do

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
end