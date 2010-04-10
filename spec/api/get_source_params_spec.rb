require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetSourceParams" do
  it_should_behave_like "ApiHelper"
  
  it "should list application sources" do
    post "/api/get_source_params", {:app_name => @appname, :api_token => @api_token, :source_id =>"SampleAdapter"}
    JSON.parse(last_response.body).should == [
      {"name"=>"rho__id", "value"=>"SampleAdapter", "type"=>"string"}, 
      {"name"=>"source_id", "value"=>1, "type"=>"integer"}, 
      {"name"=>"name", "value"=>"SampleAdapter", "type"=>"string"}, 
      {"name"=>"url", "value"=>"http://example.com", "type"=>"string"}, 
      {"name"=>"login", "value"=>"", "type"=>"string"}, 
      {"name"=>"password", "value"=>"testpass", "type"=>"string"}, 
      {"name"=>"priority", "value"=>3, "type"=>"integer"}, 
      {"name"=>"callback_url", "value"=>nil, "type"=>"string"}, 
      {"name"=>"poll_interval", "value"=>300, "type"=>"integer"}, 
      {"name"=>"partition_type", "value"=>"user", "type"=>"string"}, 
      {"name"=>"sync_type", "value"=>"incremental", "type"=>"string"}, 
      {"name"=>"queue", "value"=>nil, "type"=>"string"}, 
      {"name"=>"query_queue", "value"=>nil, "type"=>"string"}, 
      {"name"=>"cud_queue", "value"=>nil, "type"=>"string"}]
  end
  
end

