require File.join(File.dirname(__FILE__),'spec_helper')

describe "App" do
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create app with fields" do
    @a.id.should == @a_fields[:name]
    @a1 = App.with_key(@a_fields[:name])
    @a1.id.should == @a.id
    @a1.name.should == @a_fields[:name]
  end
  
  it "should create app with store" do
    @a.name.should == @a_fields[:name]
    @a.store.db.class.should == Redis 
  end
  
  it "should add source adapters" do
    @a.sources << "SimpleAdapter" 
    @a.sources << "SampleAdapter"
    @a1 = App.with_key(@a_fields[:name])
    @a1.sources.members.sort.should == ["SampleAdapter", "SimpleAdapter"]
  end
  
  it "should delete app and associated users and sources" do   
    @a.delete
    Source.is_exist?(@s_fields[:name],'name').should == false
    User.is_exist?(@u_fields[:login],'login') == false
    App.is_exist?("testapp",'name').should == false
  end
end