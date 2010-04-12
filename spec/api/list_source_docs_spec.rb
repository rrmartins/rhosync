require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListSourceDocs" do
  it_should_behave_like "ApiHelper"
  
  it "should list of shared source documents" do
    post "/api/list_source_docs", {:app_name => @test_app_name, :api_token => @api_token,
      :source_id => "SimpleAdapter", :user_id => '*'}
    JSON.parse(last_response.body).should == {
      "md"=>"source:application:__shared__:SimpleAdapter:md", 
      "errors"=>"source:application:__shared__:SimpleAdapter:errors", 
      "md_size"=>"source:application:__shared__:SimpleAdapter:md_size", 
      "md_copy"=>"source:application:__shared__:SimpleAdapter:md_copy"}
  end

  it "should list user source documents" do
    post "/api/list_source_docs", {:app_name => @test_app_name, :api_token => @api_token,
      :source_id => "SampleAdapter", :user_id => @u.id}
    JSON.parse(last_response.body).should == {
      "md"=>"source:application:testuser:SampleAdapter:md", 
      "errors"=>"source:application:testuser:SampleAdapter:errors", 
      "md_size"=>"source:application:testuser:SampleAdapter:md_size", 
      "md_copy"=>"source:application:testuser:SampleAdapter:md_copy"}
  end
  
end