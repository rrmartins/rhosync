require File.join(File.dirname(__FILE__),'spec_helper')

describe "Source" do
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create source with @s_fields" do
    @s.name.should == @s_fields[:name]
    @s.url.should == @s_fields[:url]
    @s.login.should == @s_fields[:login]
    @s.app.name.should == @a_fields[:name]
    @s.poll_interval.should == 300
    @s.priority.should == 3
    @s.callback_url.should be_nil
    (@s.refresh_time + 1).should >= Time.now.to_i
    @s.refresh_time.should <= Time.now.to_i + 1 

    @s1 = Source.with_key(@s.id)
    @s1.name.should == @s_fields[:name]
    @s1.url.should == @s_fields[:url]
    @s1.login.should == @s_fields[:login]
    @s1.app.name.should == @a_fields[:name]
    @s1.poll_interval.should == 300
    @s1.priority.should == 3
    @s1.callback_url.should be_nil
  end
  
  it "should create source with user" do
    @s.user.login.should == @u_fields[:login]
  end
  
  it "should create source with app and document" do
    @s.app.name.should == @a_fields[:name]
    @s.document.get_key.should == "md:#{@s.app.id}:#{@u.id}:0:#{@s_fields[:name]}"
  end
  
  it "should delete source" do
    @s.delete
    Source.is_exist?(@s_fields[:name],'name').should == false
  end
  
  it "should delete master and all documents associated with source" do
    masterdoc = Document.new('md',@a.id,@u.login,0,@s.name)    
    @a.store.put_data(masterdoc.get_key,@data)
    @s.delete
    @a.store.get_data(masterdoc.get_key).should == {}
    @a.store.db.keys(masterdoc.get_key).should == []
  end
end