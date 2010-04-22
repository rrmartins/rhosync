require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetClientParams" do
  it_should_behave_like "ApiHelper"
  
  it "should list client attributes" do
    post "/api/get_client_params", {:api_token => @api_token, :client_id =>@c.id}
    res = JSON.parse(last_response.body)
    res.delete_if { |attrib| attrib['name'] == 'rho__id' }
    res.sort{|x,y| x['name']<=>y['name']}.should == [
      {"name"=>"device_type", "value"=>"iPhone", "type"=>"string"}, 
      {"name"=>"device_pin", "value"=>"abcd", "type"=>"string"}, 
      {"name"=>"device_port", "value"=>"3333", "type"=>"string"}, 
      {"name"=>"user_id", "value"=>"testuser", "type"=>"string"}, 
      {"name"=>"app_id", "value"=>"application", "type"=>"string"}].sort{|x,y| x['name']<=>y['name']}
  end
  
end