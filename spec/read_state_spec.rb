require File.join(File.dirname(__FILE__),'spec_helper')

describe "ReadState" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"

  it "should create refresh with correct id" do
    @r.id.should == "#{@a_fields[:name]}:#{@u_fields[:login]}:#{@s_fields[:name]}"
  end
  
  it "should create refresh with default fields" do
    @r.poll_interval.should == 300
    @r.refresh_time.should <= Time.now.to_i
  end
  
  it "should load refresh with params" do
    @r1 = ReadState.load(:app_id => @a_fields[:name],
      :user_id => @u_fields[:login],:source_name => @s_fields[:name])
    @r1.poll_interval.should == 300
    @r1.refresh_time.should <= Time.now.to_i
  end
  
  it "should delete read_state from db" do
    ReadState.delete(@a_fields[:name])
    Store.db.keys("read_state*").should == []
  end
end