include BenchHelpers
bench_log "Simulate creating multiple blob objects"

Bench.config do |config|
  config.concurrency = 5
  config.iterations  = 2
  config.user_name = "benchuser"
  config.password = "password"
  config.adapter_name = 'BlobAdapter'
  config.get_test_server "blobapp"
  config.reset_app
  config.reset_refresh_time('BlobAdapter',0)
  config.set_server_state("test_db_storage:application:#{config.user_name}",{})

  @create_objects = []
  @create_count = 50

  config.concurrency.times do |i|
    @create_objects << []
    config.iterations.times do
      test_data = Bench.get_test_data(@create_count, true, true)
      @create_objects[i] << test_data # Bench.get_test_data(@create_count, true, true)
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

Bench.test do |config, session|
  sleep rand(2)  
  session.post "clientlogin", "#{config.base_url}/clientlogin", :content_type => :json do
    {:login => config.user_name, :password => config.password}.to_json
  end
  
  sleep rand(2)  
  session.get "clientcreate", "#{config.base_url}/clientcreate"
  session.client_id = JSON.parse(session.last_result.body)['client']['client_id']
  create_objs = @create_objects[session.thread_id][session.iteration]

  body = { :cud =>  {:source_name => 'BlobAdapter', :client_id => session.client_id,
    :blob_fields => ['img_file-rhoblob'],
    :create => create_objs, :version => 3}.to_json
  }
  session.post "create-object", "#{config.base_url}/queue_updates" do  
    body.merge!(Bench.get_image_data(create_objs)) # Add images to miltipart post
  end      
  session.last_result.verify_code(200)
  
  sleep rand(2)  
  bench_log "#{session.log_prefix} Loop to get available objects..."
  count = get_all_objects(current_line,config,session,@expected_md,create_objs)
  bench_log "#{session.log_prefix} Got #{count} available objects..."  
end

Bench.verify do |config, sessions|
  sessions.each do |session|
    bench_log "#{session.log_prefix} Loop to load all objects..."
    session.results['create-object'][0].verification_error += 
      verify_numbers(
        @datasize,get_all_objects(
          caller(0)[0].to_s,config,session,@expected_md,nil,0),session,current_line)
    bench_log "#{session.log_prefix} Loaded all objects..."
  end

  sessions.each do |session|
    actual = config.get_server_state(
      client_docname(config.user_name, session.client_id, 'BlobAdapter',:cd))
    session.results['create-object'][0].verification_error += Bench.compare_and_log(@expected_md,actual,current_line)
  end
  
  master_doc = config.get_server_state(source_docname(config.user_name, 'BlobAdapter',:md))
  Bench.verify_error = Bench.compare_and_log(@expected_md,master_doc,current_line)
  
end
