require File.join(File.dirname(__FILE__),'api_helper')

describe "GetDbDocSpec" do
  it_should_behave_like "ApiHelper"
  
  it "should return db document by name" do
    data = {'1' => {'foo' => 'bar'}}
    set_state('abc:abc' => data)
    post "/api/get_db_doc", :api_token => @api_token, :doc => 'abc:abc'
    last_response.should be_ok
    JSON.parse(last_response.body).should == data
  end
end