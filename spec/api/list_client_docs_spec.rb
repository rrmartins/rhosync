require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiListClientDocs" do
  it_should_behave_like "ApiHelper"
  
  it "should list client documents" do
    post "/api/list_client_docs", {:app_name => @appname, :api_token => @api_token,
      :source_id => "SimpleAdapter", :client_id => @c.id}
    JSON.parse(last_response.body).should == {
      "cd"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:cd", 
      "cd_size"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:cd_size", 
      "create"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:create", 
      "update"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:update", 
      "delete"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:delete", 

      "page"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:page", 
      "page_token"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:page_token", 
      "delete_page"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:delete_page", 
      "create_links"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:create_links", 
      "create_links_page"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:create_links_page", 

      "delete_errors"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:delete_errors", 
      "login_error"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:login_error", 
      "create_errors"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:create_errors", 
      "update_errors"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:update_errors", 
      "logoff_error"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:logoff_error", 

      "search"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:search",
      "search_token"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:search_token", 
      "search_errors"=>"client:rhotestapp:testuser:#{@c.id}:SimpleAdapter:search_errors"}
  end
  
end