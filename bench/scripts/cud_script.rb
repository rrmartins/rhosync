# Simulate creating multiple objects
include TrunnerHelpers

Trunner.config do |config|
  config.concurrency = 1
  config.iterations  = 1
  config.user_name = "benchuser"
  config.password = "password"
  config.app_name = "trunnerapp"
  config.get_test_server
  config.import_app
  config.create_user
  config.reset_refresh_time('MockAdapter',0)
  config.set_server_state("test_db_storage:trunnerapp:#{config.user_name}",{})
  @create_objects = []
  @create_count = 5
  config.concurrency.times do |i|
    @create_objects << []
    config.iterations.times do
      @create_objects[i] << Trunner.get_test_data(@create_count,true)
    end
  end
  @datasize = config.concurrency * config.iterations * @create_count
  @expected_md = {}
  @create_objects.each do |iteration|
    iteration.each do |objects|
      @expected_md.merge!(objects)
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
  create_objs = @create_objects[session.thread_id][session.iteration]
  session.post "create-object", config.base_url, :content_type => :json do
    {:source_name => 'MockAdapter', :client_id => session.client_id,
     :create => create_objs, :version => 3}.to_json
  end
  session.last_result.verify_code(200)
  sleep rand(10)
  logger.info "#{session.log_prefix} Loop to get all objects..."
  get_all_objects(current_line,config,session,@expected_md,create_objs)
  logger.info "#{session.log_prefix} Got all objects..."
end  

Trunner.verify do |config,sessions|
  sessions.each do |session|
    logger.info "#{session.log_prefix} Loop to load all objects..."
    session.results['create-object'][0].verification_error += 
      verify_numbers(
        @datasize,get_all_objects(
          caller(0)[0].to_s,config,session,@expected_md,nil,0),session,current_line)
    logger.info "#{session.log_prefix} Loaded all objects..."
  end
  
  sessions.each do |session|
    actual = config.get_server_state(
      client_docname(config.app_name,
                     config.user_name,
                     session.client_id,
                     'MockAdapter',:cd))
    session.results['create-object'][0].verification_error += 
      Trunner.compare_and_log(@expected_md,actual,current_line)
  end
  
  master_doc = config.get_server_state(
    source_docname(config.app_name,
                   config.user_name,
                   'MockAdapter',:md))
  Trunner.verify_error = Trunner.compare_and_log(@expected_md,master_doc,current_line)
end