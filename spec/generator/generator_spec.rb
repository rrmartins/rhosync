require File.join(File.dirname(__FILE__),'generator_spec_helper')

describe "Generator" do
  appname = 'mynewapp'
  source = 'mysource'
  path = File.expand_path(File.join(File.dirname(__FILE__)))
  
  before(:each) do
    FileUtils.mkdir_p '/tmp'
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
        "application.rb",
        'settings/settings.yml',
        'settings/license.key',
        'Rakefile',
        'spec/spec_helper.rb'
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
      FileUtils.rm_rf "/tmp/#{appname}"
      @app_generator = Rhosync::AppGenerator.new('/tmp',{},appname)
      @app_generator.invoke!
      @generator = Rhosync::SourceGenerator.new("/tmp/#{appname}",{},source)
    end
    
    it "should create new source adapter and spec" do
      @generator.should create("/tmp/#{appname}/sources/#{source}.rb")
      @generator.should create("/tmp/#{appname}/spec/sources/#{source}_spec.rb")
    end
  end
  
end