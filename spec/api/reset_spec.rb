require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiReset" do
  it_should_behave_like "ApiHelper" do
    it "should reset and re-create rhoadmin user with bootstrap" do
      Store.put_data('somedoc',{ '1' => {'foo'=>'bar'}})
      post "/api/reset", :api_token => @api_token
      App.is_exist?(test_app_name).should == true
      Store.get_data('somedoc').should == {}
      User.authenticate('rhoadmin','').should_not be_nil
    end

    it "should reset and re-create rhoadmin user with initializer" do
      Store.put_data('somedoc',{ '1' => {'foo'=>'bar'}})
      post "/api/reset", :api_token => @api_token
      App.is_exist?(test_app_name).should == true
      Store.get_data('somedoc').should == {}
      User.authenticate('rhoadmin','').should_not be_nil
      load File.join(Rhosync.base_directory,test_app_name+'.rb')
    end
  end
end
