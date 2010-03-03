$:.unshift File.join(File.dirname(__FILE__))
require 'trunner_spec_helper'
require 'rest_client'

describe "ResultSpec" do
  it_should_behave_like "TrunnerSpecHelper"

  before(:each) do
    @s1 = [{"foo" => {"bar" => "cake"}}]
    @s2 = [{"foo" => {"bar" => "cake1"}},{"hello" => "world"}]
    @result = Result.new("marker",:get,"some/url",0,1)
    client = mock("RestClient")
    client.stub!(:headers).and_return({'header1'=>'headervalue1'})
    client.stub!(:cookies).and_return({'session1'=>'sessval1'})
    client.stub!(:code).and_return(200)
    client.stub!(:to_s).and_return(@s1.to_json)
    @result.last_response = client
  end
  
  describe "test @last_response wrapper" do
  
    it "shold return 'code'" do
      @result.code.should == 200
    end

    it "shold return 'body'" do
      JSON.parse(@result.body).should == @s1
    end
    
    it "shold return 'cookies'" do
      @result.cookies.should == {'session1'=>'sessval1'}
    end
    
    it "shhould return 'headers'" do
      @result.headers.should == {'header1'=>'headervalue1'}
    end
    
  end
  
  it "should compare two array/hash structures" do
    Result.compare(:expected,@s1,:actual,@s2).should == [{:expected=>"cake", 
      :path=>[0, "foo", "bar"], :actual=>"cake1"}, 
      {:expected=>nil, :path=>[1], :actual=>{"hello"=>"world"}}]
  end
  
  it "should verify body" do
    @result.logger.should_receive(:error).exactly(8).times
    @result.verify_body(@s2.to_json)
    @result.verification_error.should == true
  end  

  it "should verify code" do
    @result.logger.should_receive(:error).exactly(4).times
    @result.verify_code(500)
    @result.verification_error.should == true
  end
      
end