$:.unshift File.join(File.dirname(__FILE__))
require 'trunner_spec_helper'

describe "UtilsSpec" do
  it_should_behave_like "TrunnerSpecHelper"
  include Utils
  include Logging
  
  it "should compare two identical hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value2'}}
    compare(:expected,h1,:actual,h2).should == []
  end
  
  it "should compare two different hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value3'}}
    compare(:expected,h1,:actual,h2).should == 
      [{:actual=>"value3", :path=>["key1", "key2"], :expected=>"value2"}]
  end
  
  it "should compare_and_log two identical hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value2'}}
    Logger.should_not_receive(:error)
    compare_and_log(h1,h2,'the caller').should == 0
  end
  
  it "should compare_and_log two different hashes" do
    h1 = {'key1' => {'key2' => 'value2'}}
    h2 = {'key1' => {'key2' => 'value3'}}
    logger.should_receive(:error).exactly(5).times
    compare_and_log(h1,h2,'the caller').should == 1
  end
end