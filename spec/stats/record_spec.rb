require 'rhosync'
FOO_RECORD_RESOLUTION = 2
FOO_RECORD_SIZE = 8

include Rhosync
include Rhosync::Stats

describe "Record" do
  
  before(:each) do
    @now = 9
    Store.db.flushdb
  end
  
  it "should add metric to the record and trim record size" do
    Time.stub!(:now).and_return { @now += 1; @now }
    10.times { Record.add('foo') }
    Store.db.zrange('stat:foo', 0, -1).should == ["2:13", "2:15", "2:17", "2:19"]
  end
  
  it "should add absolute metric value" do
    Time.stub!(:now).and_return { @now += 1; @now }
    time = 0
    4.times do 
      Record.add('foo',time) do |current,value|
        Record.save_average(current, value)
      end
      time += 1
    end
    Store.db.zrange('stat:foo', 0, -1).should == ["2,1:11", "2,5:13"]
  end
  
  it "should get range of metric values" do
    Time.stub!(:now).and_return { @now += 1; @now }
    10.times { Record.add('foo') }
    Record.range('foo', 0, 1).should == ["2:13", "2:15"]
  end
  
  it "should reset metric" do
    Time.stub!(:now).and_return { @now += 1; @now }
    10.times { Record.add('foo') }
    Store.db.zrange('stat:foo', 0, -1).should == ["2:13", "2:15", "2:17", "2:19"]
    Record.reset('foo')
    Store.db.zrange('stat:foo', 0, -1).should == []
  end
end