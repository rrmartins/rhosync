require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListClientDocs" do
  it_should_behave_like "ApiHelper" do
    it "should list client documents" do
      post "/api/client/list_client_docs", {:api_token => @api_token,
        :source_id => "SimpleAdapter", :client_id => @c.id}
      JSON.parse(last_response.body).should == {
        "cd"=>"client:application:testuser:#{@c.id}:SimpleAdapter:cd", 
        "cd_size"=>"client:application:testuser:#{@c.id}:SimpleAdapter:cd_size", 
        "create"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create", 
        "update"=>"client:application:testuser:#{@c.id}:SimpleAdapter:update", 
        "delete"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete", 

        "page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:page", 
        "page_token"=>"client:application:testuser:#{@c.id}:SimpleAdapter:page_token", 
        "delete_page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete_page", 
        "create_links"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_links", 
        "create_links_page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_links_page", 

        "delete_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete_errors", 
        "login_error"=>"client:application:testuser:#{@c.id}:SimpleAdapter:login_error", 
        "create_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_errors", 
        "update_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:update_errors", 
        "logoff_error"=>"client:application:testuser:#{@c.id}:SimpleAdapter:logoff_error", 

        "search"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search",
        "search_token"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search_token", 
        "search_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search_errors"}
    end
  end
end