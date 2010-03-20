require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiReset" do
  it_should_behave_like "ApiHelper"
  
  it "should reset and re-create admin user with bootstrap" do
    Store.put_data('somedoc',{'foo'=>'bar'})
    post "/api/reset", :api_token => @api_token
    App.is_exist?(@appname).should == true
    Store.get_data('somedoc').should == {}
    User.authenticate('admin','').should_not be_nil
  end
  
  it "should reset and re-create admin user with initializer" do
    Store.put_data('somedoc',{'foo'=>'bar'})
    Rhotestapp.class_eval "def self.initializer; Rhosync.bootstrap(\"#{Rhosync.base_directory}\"); end" 
    post "/api/reset", :api_token => @api_token
    App.is_exist?(@appname).should == true
    Store.get_data('somedoc').should == {}
    User.authenticate('admin','').should_not be_nil
    load File.join(Rhosync.base_directory,@appname+'.rb')
  end
end