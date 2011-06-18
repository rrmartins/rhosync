require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetDbDoc" do
  it_should_behave_like "ApiHelper" do
    it "should return db document by name" do
      data = {'1' => {'foo' => 'bar'}}
      set_state('abc:abc' => data)
      post "/api/source/get_db_doc", :api_token => @api_token, :doc => 'abc:abc'
      last_response.should be_ok
      JSON.parse(last_response.body).should == data
    end

    it "should return db document by name and data_type" do
      data = 'some string'
      set_state('abc:abc' => data)
      post "/api/source/get_db_doc", :api_token => @api_token, :doc => 'abc:abc', :data_type => :string
      last_response.should be_ok
      last_response.body.should == data
    end
  end  
end