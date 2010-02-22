Trunner.config do |config|
  config.concurrency = 5
  config.iterations  = 5
end

@all_objects = "[{\"version\":3},{\"token\":\"%s\"},{\"count\":3},{\"progress_count\":0},{\"total_count\":3},{\"insert\":{\"341\":{\"name\":\"Nexus One\",\"price\":\"$569.99\",\"brand\":\"Google\",\"created_at\":\"2010-01-12T01:40:57Z\",\"quantity\":\"9\",\"updated_at\":\"2010-02-01T18:29:53Z\",\"sku\":\"3\"},\"255\":{\"price\":\"$199.99\",\"name\":\"Storm\",\"brand\":\"BlackBerry\",\"created_at\":\"2009-11-14T09:48:23Z\",\"quantity\":\"2\",\"updated_at\":\"2010-01-19T17:20:07Z\",\"sku\":\"0233\"},\"246\":{\"price\":\"$199.99\",\"name\":\"iPhone\",\"brand\":\"Apple\",\"created_at\":\"2009-11-09T02:55:32Z\",\"quantity\":\"5\",\"updated_at\":\"2010-01-19T17:20:20Z\",\"sku\":\"55555\"}}}]"
@ack_token = "[{\"version\":3},{\"token\":\"\"},{\"count\":0},{\"progress_count\":3},{\"total_count\":3},{}]"

Trunner.test do |session|
  @host = "http://rhosyncnew.staging.rhohub.com"
  sleep rand(10)
  session.post "clientlogin", "#{@host}/apps/store/clientlogin", :content_type => :json do
    {:login => 'lars', :password => 'larspass'}.to_json
  end
  sleep rand(10)
  session.get "clientcreate", "#{@host}/apps/store/clientcreate"
  client_id = JSON.parse(session.last_result.body)['client']['client_id']
  session.get "get-cud", "#{@host}/apps/store" do
    {'source_name' => 'Product', 'client_id' => client_id}
  end
  sleep rand(10)
  token = JSON.parse(session.last_result.body)[1]['token']
  session.last_result.verify_body(@all_objects % token)
  sleep rand(10)
  session.get "ack-cud", "#{@host}/apps/store" do
    { 'source_name' => 'Product', 
      'client_id' => client_id,
      'token' => token}
  end
  session.last_result.verify_code(200)
  session.last_result.verify_body(@ack_token)
  
end  
