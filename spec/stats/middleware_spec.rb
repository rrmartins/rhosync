require 'rhosync'
require File.join(File.dirname(__FILE__),'..','spec_helper')
STATS_RECORD_RESOLUTION = 2 unless defined? STATS_RECORD_RESOLUTION
STATS_RECORD_SIZE = 8 unless defined? STATS_RECORD_SIZE

include Rhosync
include Rhosync::Stats

describe "Middleware" do
  
  before(:each) do
    @now = 10.0
    Store.db.flushdb
    app = mock('app')
    app.stub!(:call)
    @middleware = Middleware.new(app)
    Store.stub!(:lock).and_yield
  end
  
  it "should compute http average" do
    Time.stub!(:now).and_return { @now += 0.3; @now }
    env = {
      'rack.request.query_hash' => {
        'source_name' => 'SampleAdapter'
      },
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/application'
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