require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiPushObjects" do
  it_should_behave_like "ApiHelper" do
    it "should push new objects to rhosync's :md" do
      data = {'1' => @product1, '2' => @product2, '3' => @product3}
      post "/api/push_objects", :api_token => @api_token, 
        :user_id => @u.id, :source_id => @s_fields[:name], :objects => data
      last_response.should be_ok
      verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'3')
    end

    it "should push updates to existing objects to rhosync's :md" do
      data = {'1' => @product1, '2' => @product2, '3' => @product3}
      update = {'price' => '0.99', 'new_field' => 'value'}
      @s = Source.load(@s_fields[:name],@s_params)
      set_state(@s.docname(:md) => data,@s.docname(:md_size) => '3')
      update.each do |key,value|
        data['2'][key] = value
      end
      post "/api/push_objects", :api_token => @api_token, 
        :user_id => @u.id, :source_id => @s_fields[:name], :objects => {'2'=>update}
      last_response.should be_ok
      verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'3')
    end
  end  
end