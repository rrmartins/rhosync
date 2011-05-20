require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiPushDeletes" do
  it_should_behave_like "ApiHelper"
  
  it "should delete object from :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_state(@s.docname(:md) => data)
    data.delete('2')
    post "/api/push_deletes", :api_token => @api_token, 
      :user_id => @u.id, :source_id => @s_fields[:name], :objects => ['2']
    last_response.should be_ok
    verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'2')
  end
  
end