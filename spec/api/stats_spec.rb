require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiStats" do
  it_should_behave_like "ApiHelper"
  
  before(:all) do
    Rhosync.stats = true
  end
  
  after(:all) do
    Rhosync.stats = false
  end
  
  it "should retrieve metric names" do
    Store.set_value('stat:foo', '1')
    Store.set_value('stat:bar', '2')
    post "/api/stats", {
      :api_token => @api_token, 
      :names => '*'
    }
    last_response.should be_ok
    JSON.parse(last_response.body).sort.should == ['bar', 'foo']
  end
  
  it "should retrieve range metric" do
    Store.db.zadd('stat:foo', 2, "1:2")
    Store.db.zadd('stat:foo', 3, "1:3")
    post "/api/stats", {
      :api_token => @api_token, 
      :metric => 'foo', 
      :start => 0,
      :finish => -1
    }
    last_response.should be_ok
    JSON.parse(last_response.body).should == ["1:2", "1:3"]
  end
  
  it "should retrieve string metric" do
    Store.db.set('stat:foo', 'bar')
    post "/api/stats", {
      :api_token => @api_token, 
      :metric => 'foo'
    }
    last_response.should be_ok
    last_response.body.should == 'bar'
  end
  
  it "should raise error on unknown metric" do
    post "/api/stats", {
      :api_token => @api_token, 
      :metric => 'foo'
    }
    last_response.status.should == 404    
    last_response.body.should == 'Unknown metric'
  end
  
  it "should raise error if stats not enabled" do
    Rhosync.stats = false
    post "/api/stats", {
      :api_token => @api_token, 
      :metric => 'foo'
    }
    last_response.status.should == 500    
    last_response.body.should == 'Stats not enabled'
    Rhosync.stats = true
  end
end