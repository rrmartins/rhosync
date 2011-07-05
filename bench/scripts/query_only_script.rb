include BenchHelpers
bench_log "Runs simple login,clientcreate,sync session and validates response"

@datasize = 100
@expected = Bench.get_test_data(@datasize)
@all_objects = "[{\"version\":3},{\"token\":\"%s\"},{\"count\":%i},{\"progress_count\":0},{\"total_count\":%i},{\"insert\":""}]"
@ack_token = "[{\"version\":3},{\"token\":\"\"},{\"count\":0},{\"progress_count\":%i},{\"total_count\":%i},{}]"
@clients = []
@cookies = {}

Bench.config do |config|
  config.concurrency = 50
  config.iterations  = 10
  config.user_name = "benchuser"
  config.password = "password"
  config.get_test_server
  config.reset_app
  config.set_server_state("test_db_storage:application:#{config.user_name}",@expected)
  config.reset_refresh_time('MockAdapter')
  res = RestClient.post "#{config.base_url}/clientlogin", 
    {:login => config.user_name, :password => config.password}, :content_type => :json
  res.cookies['rhosync_session'] = CGI.escape(res.cookies['rhosync_session'])
  @cookies = res.cookies
  (config.concurrency*config.iterations).times do |i|
    create = RestClient.get "#{config.base_url}/clientcreate", {:cookies => @cookies}
    puts "Created client ##{i}..."
    @clients << JSON.parse(create.body)['client']['client_id']
  end
end

Bench.test do |config,session|
  client_id = @clients[session.thread_id*config.iterations+session.iteration]
  session.cookies = @cookies
  sleep rand(10)
  session.get "get-cud", "#{config.base_url}/query" do
    {'source_name' => 'MockAdapter', 'client_id' => client_id, 'p_size' => @datasize}
  end
  token = JSON.parse(session.last_result.body)[1]['token']
  session.last_result.verify_body([{:version => 3},{:token => token}, 
    {:count => @datasize},{:progress_count => 0},{:total_count => @datasize}, 
    {:insert => @expected}].to_json)
  sleep rand(10)
  session.get "ack-cud", "#{config.base_url}/query" do
    { 'source_name' => 'MockAdapter', 
      'client_id' => client_id,
      'token' => token}
  end
  session.last_result.verify_code(200)
  session.last_result.verify_body([{:version => 3},{:token => ''},{:count => 0},
    {:progress_count => @datasize},{:total_count => @datasize},{}].to_json)
end  
