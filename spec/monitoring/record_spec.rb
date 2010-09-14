require 'rhosync'

include Rhosync::Monitoring

describe "Record" do
  it "should add metric to the record" do
    pending
    Record.add('foo')
    Record.add('foo')
  end
  
  it "should not exceed record size" do
    pending
  end
  
  it "should set absolute metric value"
  
  it "should get range of metric values"
  
  it "should reset metric"
end