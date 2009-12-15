require File.join(File.dirname(__FILE__),'spec_helper')

describe "User" do
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create user with fields" do
    @u.id.should == @u_fields[:login]
    @u1 = User.with_key(@u_fields[:login])
    @u1.id.should == @u.id
    @u1.login.should == @u_fields[:login]
    @u1.email.should == @u_fields[:email]
  end
  
  it "should authenticate with proper credentials" do
    @u1 = User.authenticate(@u_fields[:login],'testpass')
    @u1.should_not be_nil
    @u1.login.should == @u_fields[:login]
    @u1.email.should == @u_fields[:email]
  end
  
  it "should fail to authenticate with invalid credentials" do
    User.authenticate(@u_fields[:login],'wrongpass').should be_nil
  end
  
  it "should fail to authenticate with nil user" do
    User.authenticate('niluser','doesnotmatter').should be_nil
  end
  
  it "should delete user and user clients" do
    clientdoc = Document.new('cd',@a.id,@u.login,@c.id,@s.name)
    @a.store.put_data(clientdoc.get_key,@data)
    cid = @c.id    
    @u.delete
    User.is_exist?(@u_fields[:login],'login').should == false
    Client.is_exist?(cid,'device_type').should == false
    @a.store.get_data(clientdoc.get_key).should == {}
  end
  
end