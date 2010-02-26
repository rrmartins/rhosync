require File.join(File.dirname(__FILE__),'api_helper')

describe "SetDbDocSpec" do
  it_should_behave_like "ApiHelper"
  
  it "should set db document by doc name and data" do
    data = {'1' => {'foo' => 'bar'}}
    post "/api/set_db_doc", :api_token => @api_token, :doc => 'abc:abc', :data => data
    last_response.should be_ok
    verify_result('abc:abc' => data)
  end
end