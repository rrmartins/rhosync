# Simulate creating multiple objects
include TrunnerHelpers

@all_objects = "[{\"version\":3},{\"token\":\"%s\"},{\"count\":%i},{\"progress_count\":0},{\"total_count\":%i},{\"insert\":""}]"
@ack_token = "[{\"version\":3},{\"token\":\"\"},{\"count\":0},{\"progress_count\":%i},{\"total_count\":%i},{}]"

Trunner.config do |config|
  config.concurrency = 5
  config.iterations  = 5
  config.user_name = "benchuser"
  config.password = "password"
  config.app_name = "trunnerapp"
  config.host = "http://rhosyncnew.staging.rhohub.com"
  config.base_url = "#{config.host}/apps/#{config.app_name}"
  config.reset_refresh_time('MockAdapter',0)
  config.set_server_state("test_db_storage:trunnerapp:#{config.user_name}",{})
  @create_objects = []
  config.concurrency.times do |i|
    @create_objects << []
    config.iterations.times do
      @create_objects[i] << Trunner.get_test_data(1)
    end
  end
end

Trunner.test do |config,session|
  sleep rand(10)
  session.post "clientlogin", "#{config.base_url}/clientlogin", :content_type => :json do
    {:login => config.user_name, :password => config.password}.to_json
  end
  sleep rand(10)
  session.get "clientcreate", "#{config.base_url}/clientcreate"
  session.client_id = JSON.parse(session.last_result.body)['client']['client_id']
  create_obj = @create_objects[session.thread_id][session.iteration]
  session.post "create-object", config.base_url, :content_type => :json do
    {:source_name => 'MockAdapter', :client_id => session.client_id,
     :create => create_obj, :version => 3}.to_json
  end
  sleep rand(10)
  session.last_result.verify_code(200)
end  

Trunner.verify do |config,sessions|
  sessions.each do |session|
    actual = config.get_server_state(
      client_docname(config.app_name,
                     config.user_name,
                     session.client_id,
                     'MockAdapter',:cd))
    session.results['create-object'].verification_error = 
      Trunner.compare_and_log(
        @create_objects[session.thread_id][session.iteration],
        actual,caller(1)[0].to_s)
  end
  @expected = {}
  @create_objects.each do |iteration|
    iteration.each do |objects|
      @expected.merge!(objects)
    end
  end
  master_doc = config.get_server_state(
    source_docname(config.app_name,
                   config.user_name,
                   'MockAdapter',:md))
  Trunner.verify_error = Trunner.compare_and_log(@expected,master_doc,caller(1)[0].to_s)
end