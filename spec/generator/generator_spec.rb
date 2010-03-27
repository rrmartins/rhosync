require File.join(File.dirname(__FILE__),'generator_spec_helper')

describe "Generator" do
  appname = 'mynewapp'
  source = 'mysource'
  path = File.expand_path(File.join(File.dirname(__FILE__)))
  
  after(:each) do
    #FileUtils.rm_rf path
  end
  
  describe "AppGenerator" do
    it "should complain if no name is specified" do
      lambda {
        Rhosync::AppGenerator.new('/tmp',{})
      }.should raise_error(Templater::TooFewArgumentsError)
    end
    
    before(:each) do
      @generator = Rhosync::AppGenerator.new('/tmp',{},appname)
    end
    
    it "should create new application files" do
      [ 
        'config.ru',
        "#{appname}.rb",
        'settings/settings.yml',
        'Rakefile'
      ].each do |template|
        @generator.should create("/tmp/#{appname}/#{template}")
      end
    end
  end
  
  describe "SourceGenerator" do
    it "should complain if no name is specified" do
      lambda {
        Rhosync::SourceGenerator.new('/tmp',{})
      }.should raise_error(Templater::TooFewArgumentsError)
    end
    
    before(:each) do
      @generator = Rhosync::SourceGenerator.new('/tmp',{},source)
    end
    
    it "should create new source adapter" do
      pending
      @generator.should create("/tmp/sources/#{source}.rb")
    end
  end
  
end