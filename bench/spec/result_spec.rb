$:.unshift File.join(File.dirname(__FILE__))
require 'trunner_spec_helper'
require 'rest_client'

describe "ResultSpec" do
  it_should_behave_like "TrunnerSpecHelper"
  
  it "should compare two arrays" do
    s1 = [{"foo" => {"bar" => "cake"}}]
    s2 = [{"foo" => {"bar" => "cake1"}},{"hello" => "world"}]
    Result.compare(s1,s2).should == [{:rvalue=>"cake", 
      :path=>[0, "foo", "bar"], :lvalue=>"cake1"}, 
      {:rvalue=>nil, :path=>[1], :lvalue=>{"hello"=>"world"}}]
  end
  
  # it "should verify_body" do
  #   @headers = {'header1'=>'headervalue1'}
  #   @cookies = {'session1'=>'sessval1'}
  #   @code = 200
  #   @body = '[{"version":3}]'
  #   client = mock("RestClient")
  #   client.stub!(:headers).and_return(@headers)
  #   client.stub!(:cookies).and_return(@cookies)
  #   client.stub!(:code).and_return(@code)
  #   client.stub!(:body).and_return(@body)
  #   r = Result.new('hello','get','/hello',1,1)
  #   r.stub!(:last_response).and_return(client)
  #   r.verify_body(@body).should == nil
  #   puts "last: #{r.last_response.inspect}"
  # end
end