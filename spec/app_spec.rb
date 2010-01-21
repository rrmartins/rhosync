require File.join(File.dirname(__FILE__),'spec_helper')

describe "App" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
    
  it "should create app with fields" do
    @a.id.should == @a_fields[:name]
    @a1 = App.load(@a_fields[:name])
    @a1.id.should == @a.id
    @a1.name.should == @a_fields[:name]
  end
  
  it "should add source adapters" do
    @a.sources << "SimpleAdapter" 
    @a.sources << "SampleAdapter"
    @a1 = App.load(@a_fields[:name])
    @a1.sources.members.sort.should == ["SampleAdapter", "SimpleAdapter"]
  end
  
  it "should delete app and associated users and sources and clients and read_states" do
    @a.delete
    Store.db.keys('*').should == []
  end
end