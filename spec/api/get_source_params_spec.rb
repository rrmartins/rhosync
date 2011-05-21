require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetSourceParams" do

  it_should_behave_like "ApiHelper" do
  
    it "should list source attributes" do
      post "/api/get_source_params", {:api_token => @api_token, :source_id =>"SampleAdapter"}
      result = JSON.parse(last_response.body).sort {|x,y| y["name"] <=> x["name"] }
      result.should == [
        {"name"=>"rho__id", "value"=>"SampleAdapter", "type"=>"string"}, 
        {"name"=>"source_id", "value"=>nil, "type"=>"integer"}, 
        {"name"=>"name", "value"=>"SampleAdapter", "type"=>"string"}, 
        {"name"=>"url", "value"=>"http://example.com", "type"=>"string"}, 
        {"name"=>"login", "value"=>"testuser", "type"=>"string"}, 
        {"name"=>"password", "value"=>"testpass", "type"=>"string"}, 
        {"name"=>"priority", "value"=>3, "type"=>"integer"}, 
        {"name"=>"callback_url", "value"=>nil, "type"=>"string"}, 
        {"name"=>"poll_interval", "value"=>300, "type"=>"integer"}, 
        {"name"=>"partition_type", "value"=>"user", "type"=>"string"}, 
        {"name"=>"sync_type", "value"=>"incremental", "type"=>"string"}, 
        {"name"=>"belongs_to", "type"=>"string", "value"=>nil},
        {"name"=>"has_many", "type"=>"string", "value"=>"FixedSchemaAdapter,brand"},
        {"name"=>"id", "value"=>"SampleAdapter", "type"=>"string"}, 
        {"name"=>"queue", "value"=>nil, "type"=>"string"}, 
        {"name"=>"query_queue", "value"=>nil, "type"=>"string"}, 
        {"name"=>"pass_through", "value"=>nil, "type"=>"string"}, 
        {"name"=>"cud_queue", "value"=>nil, "type"=>"string"}].sort {|x,y| y["name"] <=> x["name"] }
    end
  end
end

