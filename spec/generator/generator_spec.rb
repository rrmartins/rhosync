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
      expected_files = Dir["expected/application/**/*"].sort
      Dir["/tmp/#{name}/**/*"].sort.each_with_index do |file,i|
        actual = File.new(file)
        expected = File.new(expected_files[i])
        actual.path.should == expected.path
        actual.read.should == expected.read
      end
    end
  end
  
  describe "SourceGenerator" do
    
  end
  
end