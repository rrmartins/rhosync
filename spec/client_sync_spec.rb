require File.join(File.dirname(__FILE__),'spec_helper')

describe "ClientSync" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @cs = ClientSync.new(@s,@c,2)
  end
  
  describe "cud methods" do
    it "should handle receive cud" do
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.receive_cud(params)
      verify_result(@s.document.get_create_dockey => [],
        @s.document.get_update_dockey => [],
        @s.document.get_delete_dockey => [],
        @cs.clientdoc.get_create_dockey => {},
        @cs.clientdoc.get_update_dockey => {},
        @cs.clientdoc.get_delete_dockey => {})
    end
  
    it "should handle send cud" do
      data = {'1'=>@product1,'2'=>@product2}
      expected = {'insert'=>data}
      set_test_data('test_db_storage',data)
      @cs.send_cud.should == [{'version'=>ClientSync::VERSION},
        {'token'=>@a.store.get_value(@cs.clientdoc.get_page_token_dockey)},
        {'count'=>data.size},{'progress_count'=>0},
        {'total_count'=>data.size},expected]
      verify_result(@cs.clientdoc.get_page_dockey => data,
        @cs.clientdoc.get_delete_page_dockey => {},
        @cs.clientdoc.get_key => data)
    end
    
    it "should return read errors in send cud" do
      msg = "Error during query"
      data = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',data,msg,'query error')
      @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
        {"token"=>""}, {"count"=>0}, {"progress_count"=>0},{"total_count"=>0}, 
        {"source-error"=>{"query-error"=>{"message"=>msg}}}]
    end
    
    it "should return login errors in send cud" do
      @u.login = nil
      @cs.send_cud.should == [{"version"=>ClientSync::VERSION},{"token"=>""}, 
        {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
        {'source-error'=>{"login-error"=>{"message"=>"Error logging in"}}}]
    end
    
    it "should return logoff errors in send cud" do
      msg = "Error logging off"
      set_test_data('test_db_storage',{},msg,'logoff error')
      @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
        {"token"=>@a.store.get_value(@cs.clientdoc.get_page_token_dockey)}, 
        {"count"=>1}, {"progress_count"=>0}, {"total_count"=>1}, 
        {"source-error"=>{"logoff-error"=>{"message"=>msg}}, 
        "insert"=>{ERROR=>{"name"=>"logoff error", "an_attribute"=>msg}}}]
    end
    
    describe "send errors in send_cud" do
      it "should handle create errors" do
        receive_and_send_cud('create')
      end
      
      it "should handle update errors" do
        receive_and_send_cud('update')
      end
      
      it "should handle delete errors" do
        msg = "Error delete record"
        error_objs = add_error_object({},"Error delete record")
        op_data = {'delete'=>error_objs}
        puts "op_data: #{op_data.inspect}"
        @cs.receive_cud(op_data)
        @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
          {"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
          {"delete-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>error_objs[ERROR]}}]      
      end
      
      def receive_and_send_cud(operation)
        msg = "Error #{operation} record"
        op_data = {operation=>{ERROR=>{'an_attribute'=>msg,'name'=>'wrongname'}}}
        @cs.receive_cud(op_data)
        @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
          {"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
          {"#{operation}-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>op_data[operation][ERROR]}}]
      end
    end
  
    it "should handle receive_cud" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',expected)
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.receive_cud(params)
      verify_result(@s.document.get_create_dockey => [],
        @s.document.get_update_dockey => [],
        @s.document.get_delete_dockey => [],
        @cs.clientdoc.get_create_dockey => {},
        @cs.clientdoc.get_update_dockey => {},
        @cs.clientdoc.get_delete_dockey => {},
        @s.document.get_key => expected)
    end
    
    it "should handle send_cud with query_params" do
      expected = {'1'=>@product1}
      set_state('test_db_storage' => {'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @cs.send_cud(nil,params)
      verify_result(@s.document.get_key => expected,
        @cs.clientdoc.get_page_dockey => expected)
    end
  end
  
  describe "reset" do
    it "should handle reset" do
      set_state(@cs.clientdoc.get_key => @data)
      ClientSync.reset(@a,@u,@c)
      verify_result(@cs.clientdoc.get_key => {})
    end
  end
  
  describe "search" do
    before(:each) do
      @s_fields[:name] = 'SimpleAdapter'
      @s1 = Source.create(@s_fields)
      @cs1 = ClientSync.new(@s1,@c,2)
    end
    
    it "should handle search" do
      params = {:search => {'name' => 'iPhone'}}
      set_state('test_db_storage' => @data)
      res = @cs.search(params)
      token = @a.store.get_value(@cs.clientdoc.get_search_token_dockey)
      res.should == [{'version'=>ClientSync::VERSION},{'search_token'=>token},
        {'source'=>@s.name},{'count'=>1},{'insert'=>{'1'=>@product1}}]
      verify_result(@cs.clientdoc.get_search_dockey => {'1'=>@product1},
        @cs.clientdoc.get_search_errors_dockey => {})
    end
    
    it "should handle search with nil result" do
      params = {:search => {'name' => 'foo'}}
      set_state('test_db_storage' => @data)
      @cs.search(params).should == []
      verify_result(@cs.clientdoc.get_search_dockey => {},
        @cs.clientdoc.get_search_errors_dockey => {})
    end
    
    it "should resend search by search_token" do
      @source = @s
      set_state({@cs.clientdoc.get_search_dockey => {'1'=>@product1}})
      token = compute_token @cs.clientdoc.get_search_token_dockey
      @cs.search({:resend => true,:search_token => token}).should == [{'version'=>ClientSync::VERSION},
        {'search_token'=>token},{'source'=>@s.name},{'count'=>1},{'insert'=>{'1'=>@product1}}]
      verify_result(@cs.clientdoc.get_search_dockey => {'1'=>@product1},
        @cs.clientdoc.get_search_errors_dockey => {},
        @cs.clientdoc.get_search_token_dockey => token)
    end
    
    it "should handle search ack" do
      @source = @s
      set_state({@cs.clientdoc.get_search_dockey => {'1'=>@product1}})
      token = compute_token @cs.clientdoc.get_search_token_dockey
      @cs.search({:search_token => token}).should == []
      verify_result(@cs.clientdoc.get_search_dockey => {},
        @cs.clientdoc.get_search_errors_dockey => {},
        @cs.clientdoc.get_search_token_dockey => nil)
    end
    
    it "should handle search all" do
      sources = ['SampleAdapter']
      set_state('test_db_storage' => @data)
      res = ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}})
      token = @a.store.get_value(@cs.clientdoc.get_search_token_dockey)
      res.should == [[{'version'=>ClientSync::VERSION},{'search_token'=>token},
        {'source'=>sources[0]},{'count'=>1},{'insert'=>{'1'=>@product1}}]]
      verify_result(@cs.clientdoc.get_search_dockey => {'1'=>@product1},
        @cs.clientdoc.get_search_errors_dockey => {})
    end
    
    it "should handle search all error" do
      sources = ['SampleAdapter']
      msg = "Error during search"
      error = set_test_data('test_db_storage',@data,msg,'search error')
      res = ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}})
      token = @a.store.get_value(@cs.clientdoc.get_search_token_dockey)
      res.should == [[{'version'=>ClientSync::VERSION},
        {'source'=>sources[0]},{'search-error'=>{'search-error'=>{'message'=>msg}}}]]
      verify_result(@cs.clientdoc.get_search_dockey => {},
        @cs.clientdoc.get_search_errors_dockey => {'search-error'=>{'message'=>msg}})
    end
    
    it "should handle search all login error" do
      @u.login = nil
      sources = ['SampleAdapter']
      msg = "Error logging in"
      error = set_test_data('test_db_storage',@data,msg,'search error')
      ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}}).should == [
        [{'version'=>ClientSync::VERSION},{'source'=>sources[0]},
        {'search-error'=>{'login-error'=>{'message'=>msg}}}]]
      verify_result(@cs.clientdoc.get_search_dockey => {},
        @cs.clientdoc.get_search_errors_dockey => {'login-error'=>{'message'=>msg}},
        @cs.clientdoc.get_search_token_dockey => nil)
    end
    
    it "should handle multiple source search all" do
      set_test_data('test_db_storage',@data)
      sources = ['SampleAdapter','SimpleAdapter']
      res = ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}})
      token = @a.store.get_value(@cs.clientdoc.get_search_token_dockey)
      res.should == [[{"version"=>ClientSync::VERSION},{'search_token'=>token},
        {"source"=>"SampleAdapter"},{"count"=>1},{"insert"=>{'1'=>@product1}}],[]]
    end
    
    it "should handle search and accumulate params" do
      set_test_data('test_db_storage',@data)
      sources = ['SimpleAdapter','SampleAdapter']
      res = ClientSync.search_all(@c,{:sources => sources,:search => {'search'=>'bar'}})
      token = @a.store.get_value(@cs1.clientdoc.get_search_token_dockey)
      token1 = @a.store.get_value(@cs.clientdoc.get_search_token_dockey)
      res.should == [[{"version"=>ClientSync::VERSION}, {'search_token'=>token},
        {"source"=>"SimpleAdapter"},{"count"=>1},{"insert"=>{'obj'=>{'foo'=>'bar'}}}],
        [{"version"=>ClientSync::VERSION},{'search_token'=>token1},{"source"=>"SampleAdapter"}, 
         {"count"=>1}, {"insert"=>{'1'=>@product1}}]]      
    end
  end
  
  describe "page methods" do
    it "should return diffs between master documents and client documents limited by page size" do
      @store.put_data(@s.document.get_key,@data).should == true
      @store.get_data(@s.document.get_key).should == @data
      @store.put_value(@s.document.get_datasize_dockey,@data.size)
      @expected = {'1'=>@product1,'2'=>@product2}
      @cs.compute_page.should == @expected
      @store.get_value(@cs.clientdoc.get_datasize_dockey).to_i.should == 0
      @store.get_data(@cs.clientdoc.get_page_dockey).should == @expected      
    end

    it "appends diff to the client document" do
      @cd = {'3'=>@product3}  
      @store.put_data(@cdoc.get_key,@cd)
      @store.get_data(@cdoc.get_key).should == @cd

      @page = {'1'=>@product1,'2'=>@product2}
      @expected = {'1'=>@product1,'2'=>@product2,'3'=>@product3}

      @store.put_data(@cdoc.get_key,@page,true).should == true
      @store.get_data(@cdoc.get_key).should == @expected
    end

    it "should return deleted objects in the client document" do
      @store.put_data(@s.document.get_key,@data).should == true
      @store.get_data(@s.document.get_key).should == @data

      @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
      @store.put_data(@cs.clientdoc.get_key,@cd)
      @store.get_data(@cs.clientdoc.get_key).should == @cd

      @expected = {'4'=>@product4}
      @cs.compute_deleted_page.should == @expected
      @store.get_data(@cs.clientdoc.get_delete_page_dockey).should == @expected
    end  

    it "should delete objects from client document" do
      @store.put_data(@s.document.get_key,@data).should == true
      @store.get_data(@s.document.get_key).should == @data

      @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
      @store.put_data(@cs.clientdoc.get_key,@cd)
      @store.get_data(@cs.clientdoc.get_key).should == @cd

      @store.delete_data(@cs.clientdoc.get_key,@cs.compute_deleted_page).should == true
      @store.get_data(@cs.clientdoc.get_key).should == @data 
    end
    
    it "should resend page if page exists and no token provided" do
      expected = {'1'=>@product1}
      set_test_data('test_db_storage',{'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @cs.send_cud(nil,params)
      token = @store.get_value(@cs.clientdoc.get_page_token_dockey)
      @cs.send_cud.should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},{'insert' => expected}]
      @cs.send_cud(token).should == [{"version"=>ClientSync::VERSION},{"token"=>""}, 
        {"count"=>0}, {"progress_count"=>1}, {"total_count"=>1}, {}]
      @store.get_data(@cs.clientdoc.get_page_dockey).should == {}              
      @store.get_value(@cs.clientdoc.get_page_token_dockey).should be_nil
    end
    
    it "should remove page and delete page when token is acknowledged" do
      pending
    end
  end
end