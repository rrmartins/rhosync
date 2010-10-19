require 'rhosync'
STATS_RECORD_RESOLUTION = 2
STATS_RECORD_SIZE = 8

include Rhosync
include Rhosync::Stats

describe "Middleware" do
  
  before(:each) do
    @now = 10.0
    Store.db.flushdb
    app = mock('app')
    app.stub!(:call)
    @middleware = Middleware.new(app)
  end
  
  it "should compute http average" do
    Time.stub!(:now).and_return { @now += 0.3; @now }
    env = {
      'rack.request.query_hash' => {
        'source_id' => 'SampleAdapter'
      },
      'REQUEST_METHOD' => 'GET',
      'REQUEST_PATH' => '/application'
    }
    10.times { @middleware.call(env) }
    metric = 'http:GET:/application:SampleAdapter'
    Record.key(metric).should == "stat:#{metric}"
    Record.range(metric, 0, -1).should == [
      "2.0,0.600000000000002:12", 
      "2.0,0.600000000000002:14", 
      "2.0,0.600000000000002:16", 
      "2.0,0.600000000000002:18"
    ]
  end  
end