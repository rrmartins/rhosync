require File.join(File.dirname(__FILE__),'..','api_helper')

describe "RhosyncApiSetDbDoc" do
  it_should_behave_like "ApiHelper" do
    it "should set db document by doc name and data" do
      data = {'1' => {'foo' => 'bar'}}
      post "/api/source/set_db_doc", :api_token => @api_token, :doc => 'abc:abc', :data => data
      last_response.should be_ok
      verify_result('abc:abc' => data)
    end

    it "should set db document by doc name, data type, and data" do
      data = 'some string'
      post "/api/source/set_db_doc", :api_token => @api_token, :doc => 'abc:abc:str', :data => data, :data_type => :string
      last_response.should be_ok
      verify_result('abc:abc:str' => data)
    end
  end  
end