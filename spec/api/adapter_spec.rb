require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiDeleteUser" do
  it_should_behave_like "ApiHelper" do 
    
    it "should save adapter url" do
      params = {:api_token => @api_token,
        :attributes => {:adapter_url => 'http://test.com'}}
      post "/api/source/save_adapter", params
      last_response.should be_ok
    end
    
    it "should get adapter url" do
      params = {:api_token => @api_token,
        :attributes => {:adapter_url => 'http://test.com'}}
      post "/api/source/get_adapter", params
      last_response.should be_ok
    end
    
    it "should get check deprecation warning in /api/get_adapter" do
      params = {:api_token => @api_token,
        :attributes => {:adapter_url => 'http://test.com'}}
      post "/api/get_adapter", params
      last_response.should be_ok
      last_response.headers["Warning"].index('deprecated').should_not == nil
    end
  end  
 
end
