require File.join(File.dirname(__FILE__),'spec_helper')

describe "Source" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create and load source with @s_fields and @s_params" do
    @s.name.should == @s_fields[:name]
    @s.url.should == @s_fields[:url]
    @s.login.should == @s_fields[:login]
    @s.app.name.should == @a_fields[:name]
    @s.priority.should == 3
    @s.callback_url.should be_nil
    @s.app_id.should == @s_params[:app_id]
    @s.user_id.should == @s_params[:user_id]

    @s1 = Source.load(@s.id,@s_params)
    @s1.name.should == @s_fields[:name]
    @s1.url.should == @s_fields[:url]
    @s1.login.should == @s_fields[:login]
    @s1.app.name.should == @a_fields[:name]
    @s1.priority.should == 3
    @s1.callback_url.should be_nil
    @s1.app_id.should == @s_params[:app_id]
    @s1.user_id.should == @s_params[:user_id]
  end
  
  it "should create source with user" do
    @s.user.login.should == @u_fields[:login]
  end
  
  it "should create source with app and document" do
    @s.app.name.should == @a_fields[:name]
    @s.docname(:md).should == "source:#{@s.app.id}:#{@u.id}:#{@s_fields[:name]}:md"
  end
    
  it "should delete source" do
    @s.delete
    Source.is_exist?(@s_fields[:name]).should == false
  end
  
  it "should delete master and all documents associated with source" do
    set_state(@s.docname(:md) => @data)
    @s.delete
    verify_result(@s.docname(:md) => {})
    Store.db.keys(@s.docname('*')).should == []
  end
  
  it "should create source with default partition user" do
    @s1 = Source.load(@s_fields[:name],{:app_id => @a.id,:user_id => '*'})
    @s1.partition.should == :user
  end
  
  it "should create correct docname based on partition scheme" do
    @s.partition = :app
    @s.docname(:md).should == "source:#{@s.app.id}:__shared__:#{@s_fields[:name]}:md"
  end
end