require File.join(File.dirname(__FILE__),'generator_spec_helper')

describe "Generator" do
  name = 'mynewapp'
  
  describe "AppGenerator" do
    it "should complain if no name is specified" do
      lambda {
        Rhosync::AppGenerator.new('/tmp',{})
      }.should raise_error(Templater::TooFewArgumentsError)
    end
    
    before do
      @generator = Rhosync::AppGenerator.new('/tmp',{},name)
    end
    
    it "should create new application files" do
    end
  end
  
  describe "SourceGenerator" do
    
  end
  
end