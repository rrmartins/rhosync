require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListSourceDocs" do
  it_should_behave_like "ApiHelper"
  
  it "should list of shared source documents" do
    post "/api/list_source_docs", {:app_name => @appname, :api_token => @api_token,
      :source_id => "SimpleAdapter", :user_id => '*'}
    JSON.parse(last_response.body).should == {
      "md"=>"source:rhotestapp:__shared__:SimpleAdapter:md", 
      "errors"=>"source:rhotestapp:__shared__:SimpleAdapter:errors", 
      "md_size"=>"source:rhotestapp:__shared__:SimpleAdapter:md_size", 
      "md_copy"=>"source:rhotestapp:__shared__:SimpleAdapter:md_copy"}
  end

  it "should list user source documents" do
    post "/api/list_source_docs", {:app_name => @appname, :api_token => @api_token,
      :source_id => "SampleAdapter", :user_id => @u.id}
    JSON.parse(last_response.body).should == {
      "md"=>"source:rhotestapp:testuser:SampleAdapter:md", 
      "errors"=>"source:rhotestapp:testuser:SampleAdapter:errors", 
      "md_size"=>"source:rhotestapp:testuser:SampleAdapter:md_size", 
      "md_copy"=>"source:rhotestapp:testuser:SampleAdapter:md_copy"}
  end
  
end