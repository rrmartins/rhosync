require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListSources" do
  it_should_behave_like "ApiHelper"
  
  it "should list all application sources" do
    post "/api/list_sources", {:api_token => @api_token}
    JSON.parse(last_response.body).should == ["SimpleAdapter", "SampleAdapter"]
  end

  it "should list all application sources using partition_type param" do
    post "/api/list_sources", 
      {:api_token => @api_token, :partition_type => 'all'}
    JSON.parse(last_response.body).should == ["SimpleAdapter", "SampleAdapter"]
  end
  
  it "should list app partition sources" do
    post "/api/list_sources", {:api_token => @api_token, :partition_type => :app}
    JSON.parse(last_response.body).should == ["SimpleAdapter"]
  end

  it "should list user partition sources" do
    post "/api/list_sources", {:api_token => @api_token, :partition_type => :user}
    JSON.parse(last_response.body).should == ["SampleAdapter"]
  end
  
end