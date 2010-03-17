module TrunnerHelpers
  include Trunner::Logging
  include Trunner::Utils
  
  def client_docname(app_id,user_id,client_id,source_name,doctype)
    "client:#{app_id}:#{user_id}:#{client_id}:#{source_name}:#{doctype}"
  end
  
  def source_docname(app_id,user_id,source_name,doctype)
    "source:#{app_id}:#{user_id}:#{source_name}:#{doctype}"
  end
  
  def verify_presence_of_keys(expected,actual,session,caller)
    verification_error = 0
    expected.each do |key,object|
      if !actual or !actual.include?(key) or actual[key]['l'] != key 
        logger.error "#{session.log_prefix} Verify error at: " + caller
        logger.error "#{session.log_prefix} Unexpected id for object #{key}"
        verification_error += 1
      end
    end
    verification_error
  end
  
  def verify_numbers(expected,actual,session,caller)
    if expected != actual
      logger.error "#{session.log_prefix} Verify error at: " + caller
      logger.error "#{session.log_prefix} Expected #{expected}"
      logger.error "#{session.log_prefix} Actual  #{actual}"
      1
    else
      0
    end
  end

  def verify_count(session,caller)
    expected = JSON.parse(session.last_result.body)[2]['count']
    result = JSON.parse(session.last_result.body)[5]
    actual = 0
    actual += result['delete'].size if result.include?('delete')
    actual += result['insert'].size if result.include?('insert')
    session.last_result.verification_error += verify_numbers(expected,actual,session,caller)
  end
  
  def verify_objects(expected_md,actual,session,marker,caller)
    return if actual.nil?
    actual.each do |key,object|
      if expected_md.include?(key)
        session.last_result.verification_error += 
          compare_and_log(expected_md[key],object,caller) 
      else
        logger.error "#{session.log_prefix} Verify error at: " + caller
        logger.error "#{session.log_prefix} Unknown object: #{object.inspect}"
        session.last_result.verification_error += 1
      end
    end
  end  
  
  def verify_links(session,create_objs,caller)
    links = JSON.parse(session.last_result.body)[5]['links']
    session.last_result.verification_error += 
      verify_presence_of_keys(create_objs,links,session,caller) if links
  end
    
  def current_line
    caller(1)[0].to_s
  end  
      
  def get_all_objects(caller,config,session,expected_md,create_objs=nil,timeout=10)
    session.get "get-cud", config.base_url do
      {'source_name' => 'MockAdapter', 'client_id' => session.client_id, 'p_size' => @datasize}
    end
    sleep rand(timeout)
    token = JSON.parse(session.last_result.body)[1]['token']
    progress_count = JSON.parse(session.last_result.body)[3]['progress_count']
    return progress_count if token == ''
    
    verify_count(session,caller+"\n"+current_line)
    verify_objects(expected_md,JSON.parse(session.last_result.body)[5]['insert'],
      session,"get-cud",caller+"\n"+current_line)
    verify_links(session,create_objs,caller+"\n"+current_line) if create_objs

    while token != '' do
      sleep rand(timeout)
      session.get "ack-cud", config.base_url do
        { 'source_name' => 'MockAdapter', 
          'client_id' => session.client_id,
          'token' => token}
      end
      session.last_result.verify_code(200)
      verify_count(session,caller+"\n"+current_line)
      verify_objects(expected_md,JSON.parse(session.last_result.body)[5]['insert'],
        session,"ack-cud",caller+"\n"+current_line)
      verify_links(session,create_objs,caller+"\n"+current_line) if create_objs
      
      token = JSON.parse(session.last_result.body)[1]['token']
      progress_count = JSON.parse(session.last_result.body)[3]['progress_count']
    end
    progress_count
  end
end