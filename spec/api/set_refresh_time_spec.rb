require File.join(File.dirname(__FILE__),'api_helper')

describe "SetRefreshTimeSpec" do
  it_should_behave_like "ApiHelper"
  
  it "should set refresh time to 100s from 'now'" do
    upload_test_apps
    before = Time.now.to_i
    post "/api/set_refresh_time", :api_token => @api_token, :source_name => @s_fields[:name],
      :app_name => @a_fields[:name], :user_name => @u_fields[:login], :refresh_time => 100
    after = Time.now.to_i
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.read_state.refresh_time.should >= before + 100
    @s.read_state.refresh_time.should <= after + 100
  end
  
  it "should set refresh time to 'now' if no refresh_time provided" do
    upload_test_apps
    before = Time.now.to_i
    post "/api/set_refresh_time", :api_token => @api_token, :source_name => @s_fields[:name],
      :app_name => @a_fields[:name], :user_name => @u_fields[:login]
    after = Time.now.to_i
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.read_state.refresh_time.should >= before
    @s.read_state.refresh_time.should <= after
  end
  
  it "should set poll interval" do
    upload_test_apps
    post "/api/set_refresh_time", :api_token => @api_token, :source_name => @s_fields[:name],
      :app_name => @a_fields[:name], :user_name => @u_fields[:login], :poll_interval => 100
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.poll_interval.should == 100
  end
  
  it "should should not set nil poll interval" do
    upload_test_apps
    post "/api/set_refresh_time", :api_token => @api_token, :source_name => @s_fields[:name],
      :app_name => @a_fields[:name], :user_name => @u_fields[:login], :poll_interval => nil
    last_response.should be_ok
    @s = Source.load(@s.id,@s_params)
    @s.poll_interval.should == 300
  end
end