require File.join(File.dirname(__FILE__),'spec_helper')

describe "ClientSync" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    it "should raise Argument error if no client or source is provided" do
      lambda { ClientSync.new(@s,nil,2) }.should raise_error(ArgumentError,'Unknown client')
      lambda { ClientSync.new(nil,@c,2) }.should raise_error(ArgumentError,'Unknown source')
    end

    before(:each) do
      @cs = ClientSync.new(@s,@c,2)
    end
    
    it "should handle send cud if pass_through is set" do
      data = {'1'=>@product1,'2'=>@product2}
      expected = {'insert'=>data}
      set_test_data('test_db_storage',data)
      @s.pass_through = 'true'
      @cs.send_cud.should == [{'version'=>ClientSync::VERSION},
        {'token'=>@c.get_value(:page_token)},
        {'count'=>data.size},{'progress_count'=>data.size},
        {'total_count'=>data.size},expected]
      verify_result(@cs.client.docname(:page) => {},
        @cs.client.docname(:cd) => {})
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
        {"token"=>@c.get_value(:page_token)}, 
        {"count"=>1}, {"progress_count"=>0}, {"total_count"=>1}, 
        {"source-error"=>{"logoff-error"=>{"message"=>msg}}, 
        "insert"=>{ERROR=>{"name"=>"logoff error", "an_attribute"=>msg}}}]
    end
    
    describe "send errors in send_cud" do
      it "should handle create errors" do
        receive_and_send_cud('create')
      end

      it "should handle send cud" do
        data = {'1'=>@product1,'2'=>@product2}
        expected = {'insert'=>data}
        set_test_data('test_db_storage',data)
        @cs.send_cud.should == [{'version'=>ClientSync::VERSION},
          {'token'=>@c.get_value(:page_token)},
          {'count'=>data.size},{'progress_count'=>0},
          {'total_count'=>data.size},expected]
        verify_result(@cs.client.docname(:page) => data,
          @cs.client.docname(:delete_page) => {},
          @cs.client.docname(:cd) => data)
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
          {"token"=>@c.get_value(:page_token)}, 
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
          @cs.receive_cud(op_data)
          @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
            {"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
            {"delete-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>error_objs[ERROR]}}]      
        end

        it "should send cud errors only once" do
          msg = "Error delete record"
          error_objs = add_error_object({},"Error delete record")
          op_data = {'delete'=>error_objs}
          @cs.receive_cud(op_data)
          @cs.send_cud.should == [{"version"=>ClientSync::VERSION},
            {"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},
            {"delete-error"=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>error_objs[ERROR]}}]
          verify_result(@c.docname(:delete_errors) => {})
          @cs.send_cud.should ==   [{"version"=>ClientSync::VERSION},
            {"token"=>""}, {"count"=>0}, {"progress_count"=>0}, {"total_count"=>0},{}]
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
        set_state(@s.docname(:md) => {'3'=>@product3},
          @c.docname(:cd) => {'3'=>@product3})
        params = {'create'=>{'1'=>@product1},
          'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
        @cs.receive_cud(params)
        verify_result(@cs.client.docname(:create) => {},
          @cs.client.docname(:update) => {},
          @cs.client.docname(:delete) => {},
          @s.docname(:md) => {},
          @c.docname(:cd) => {})
      end

      it "should handle blob upload in receive_cud" do
        pending
      end

      it "should handle send_cud with query_params" do
        expected = {'1'=>@product1}
        set_state('test_db_storage' => {'1'=>@product1,'2'=>@product2,'4'=>@product4})
        params = {'name' => 'iPhone'}
        @cs.send_cud(nil,params)
        verify_result(@s.docname(:md) => expected,
          @cs.client.docname(:page) => expected)
      end
    end

    describe "reset" do
      it "should handle reset" do
        set_state(@c.docname(:cd) => @data)
        ClientSync.reset(@c)
        verify_result(@c.docname(:cd) => {})
        Client.load(@c.id,{:source_name => @s.name}).should_not be_nil
      end
    end

    describe "search" do
      before(:each) do
        @s_fields[:name] = 'SimpleAdapter'
        @c1 = Client.create(@c_fields,{:source_name => @s_fields[:name]})
        @s1 = Source.create(@s_fields,@s_params)
        @cs1 = ClientSync.new(@s1,@c1,2)
      end

      def search_and_verify_res(params)
        res = @cs.search(params)
        token = @c.get_value(:search_token)
        res[0]['version'].should == ClientSync::VERSION
        res[1]['token'].should == token
        res[2]['source'].should == @s.name
        res[3]['count'].should == 1
        res[4]['insert']
      end

      it "should handle search" do
        params = {:search => {'name' => 'iPhone'}}
        set_state('test_db_storage' => @data)
        res = @cs.search(params)
        token = @c.get_value(:search_token)
        res.should == [{'version'=>ClientSync::VERSION},{'token'=>token},
          {'source'=>@s.name},{'count'=>1},{'insert'=>{'1'=>@product1}}]
        verify_result(@c.docname(:search) => {'1'=>@product1},
          @c.docname(:search_errors) => {})
      end

      it "should handle search with no params" do
        @cs.p_size = @data.size
        set_state('test_db_storage' => @data)
        res = @cs.search(nil)
        token = @c.get_value(:search_token)
        res.should == [{'version'=>ClientSync::VERSION},{'token'=>token},
          {'source'=>@s.name},{'count'=>@data.size},{'insert'=>@data}]
        verify_result(@c.docname(:search) => @data,
          @c.docname(:search_errors) => {})
      end

      it "should handle search with more than one page" do
        @cs.p_size = 1
        params = {:search => {'name' => 'iPhone'}}
        product4 = {'name' => 'iPhone', 'price' => '99.99'}
        @data['4'] = product4
        set_state('test_db_storage' => @data)
        inserts = search_and_verify_res(params)
        verify_result(@c.docname(:search) => {'1'=>@product1,'4'=>product4},
          @c.docname(:cd_size) => '1',
          @s.docname(:md_size) => '1',
          @c.docname(:cd) => @c.get_data(:search_page),
          @s.docname(:md) => @c.get_data(:search_page),
          @c.docname(:search_errors) => {})

        # ack the token
        params[:token] = @c.get_value(:search_token)
        new_inserts = search_and_verify_res(params)
        inserts.merge!(new_inserts)
        verify_result(@c.docname(:search) => {'1'=>@product1,'4'=>product4},
          @c.docname(:cd) => inserts,
          @s.docname(:md) => inserts,
          @c.docname(:search_errors) => {})
        @c.get_data(:search_page).size.should == 1

        # ack the last token
        params[:token] = @c.get_value(:search_token)
        @cs.search(params).should == []
        verify_result(@c.docname(:search) => {},
          @c.docname(:cd) => inserts,
          @s.docname(:md) => inserts,
          @c.docname(:search_errors) => {},
          @c.docname(:search_page) => {},
          @cs.client.docname(:search_token) => nil)
      end

      it "should handle search with nil result" do
        params = {:search => {'name' => 'foo'}}
        set_state('test_db_storage' => @data)
        @cs.search(params).should == []
        verify_result(@c.docname(:search) => {},
          @c.docname(:search_errors) => {})
      end

      it "should resend search by search_token" do
        @source = @s
        set_state({@c.docname(:search_page) => {'1'=>@product1}})
        token = compute_token @cs.client.docname(:search_token)
        @cs.search({:resend => true,:token => token}).should == [{'version'=>ClientSync::VERSION},
          {'token'=>token},{'source'=>@s.name},{'count'=>1},{'insert'=>{'1'=>@product1}}]
        verify_result(@c.docname(:search_page) => {'1'=>@product1},
          @c.docname(:search_errors) => {},
          @cs.client.docname(:search_token) => token)
      end

      it "should handle search ack" do
        @source = @s
        set_state({@c.docname(:search) => {'1'=>@product1}})
        set_state({@c.docname(:cd) => {'1'=>@product1}})
        token = compute_token @cs.client.docname(:search_token)
        @cs.search({:token => token}).should == []
        verify_result(@c.docname(:search) => {},
          @c.docname(:search_errors) => {},
          @cs.client.docname(:search_token) => nil)
      end

      it "should return error on invalid ack token" do
        set_state({@c.docname(:search_page) => {'1'=>@product1}})
        set_state({@c.docname(:search_token) => 'validtoken'})
        @cs.search(
          {:token => 'abc',
          :search => {'name' => 'iPhone'}}
        ).should == [{'version'=>ClientSync::VERSION},
          {'source'=>@s.name},{'search-error'=>{'search-error'=>
          {'message'=>"Search error - invalid token"}}}]
        verify_result(@c.docname(:search) => {},
          @c.docname(:search_errors) => {},
          @cs.client.docname(:search_token) => nil)
      end

      it "should handle search all" do
        sources = [{'name'=>'SampleAdapter'}]
        set_state('test_db_storage' => @data)
        res = ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}})
        token = Store.get_value(@cs.client.docname(:search_token))
        res.should == [[{'version'=>ClientSync::VERSION},{'token'=>token},
          {'source'=>sources[0]['name']},{'count'=>1},{'insert'=>{'1'=>@product1}}]]
        verify_result(@c.docname(:search) => {'1'=>@product1},
          @c.docname(:search_errors) => {})
      end

      it "should handle search all error" do
        sources = [{'name'=>'SampleAdapter'}]
        msg = "Error during search"
        error = set_test_data('test_db_storage',@data,msg,'search error')
        res = ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}})
        token = Store.get_value(@cs.client.docname(:search_token))
        res.should == [[{'version'=>ClientSync::VERSION},
          {'source'=>sources[0]['name']},{'search-error'=>{'search-error'=>{'message'=>msg}}}]]
        verify_result(@c.docname(:search) => {})
      end

      it "should handle search all login error" do
        @u.login = nil
        sources = [{'name'=>'SampleAdapter'}]
        msg = "Error logging in"
        error = set_test_data('test_db_storage',@data,msg,'search error')
        ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}}).should == [
          [{'version'=>ClientSync::VERSION},{'source'=>sources[0]['name']},
          {'search-error'=>{'login-error'=>{'message'=>msg}}}]]
        verify_result(@c.docname(:search) => {},
          @c.docname(:search_token) => nil)
      end

      it "should handle multiple source search all" do
        set_test_data('test_db_storage',@data)
        sources = [{'name'=>'SimpleAdapter'},{'name'=>'SampleAdapter'}]
        res = ClientSync.search_all(@c,{:sources => sources,:search => {'name' => 'iPhone'}})
        @c.source_name = 'SampleAdapter'
        token = Store.get_value(@c.docname(:search_token))
        res.sort.should == [[{"version"=>ClientSync::VERSION},{'token'=>token},
          {"source"=>"SampleAdapter"},{"count"=>1},{"insert"=>{'1'=>@product1}}],[]].sort
      end

      it "should handle search and accumulate params" do
        set_test_data('test_db_storage',@data)
        sources = [{'name'=>'SimpleAdapter'},{'name'=>'SampleAdapter'}]
        res = ClientSync.search_all(@c,{:sources => sources,:search => {'search'=>'bar'}})
        @c.source_name = 'SimpleAdapter'
        token = Store.get_value(@c.docname(:search_token))
        @c.source_name = 'SampleAdapter'
        token1 = Store.get_value(@c.docname(:search_token))
        res.should == [[{"version"=>ClientSync::VERSION}, {'token'=>token},
          {"source"=>"SimpleAdapter"},{"count"=>1},{"insert"=>{'obj'=>{'foo'=>'bar'}}}],
          [{"version"=>ClientSync::VERSION},{'token'=>token1},{"source"=>"SampleAdapter"}, 
           {"count"=>1}, {"insert"=>{'1'=>@product1}}]]      
      end

      it "should handle search and ack of search results" do
        set_test_data('test_db_storage',@data)
        sources = [{'name'=>'SimpleAdapter'},{'name'=>'SampleAdapter'}]
        ClientSync.search_all(@c,{:sources => sources,:search => {'search'=>'bar'}})
        @c.source_name = 'SimpleAdapter'
        token = Store.get_value(@c.docname(:search_token))
        token.should_not be_nil
        sources[0]['token'] = token
        Store.get_data(@c.docname(:search)).should == {'obj'=>{'foo'=>'bar'}}
        @c.source_name = 'SampleAdapter'
        token1 = Store.get_value(@c.docname(:search_token))
        token1.should_not be_nil
        sources[1]['token'] = token1
        Store.get_data(@c.docname(:search)).should == {'1'=>@product1}
        # do ack on multiple sources
        res = ClientSync.search_all(@c,{:sources => sources,:search => {'search'=>'bar'}})
        @c.source_name = 'SimpleAdapter'
        token = Store.get_value(@c.docname(:search_token))
        token.should be_nil
        Store.get_data(@c.docname(:search)).should == {}
        @c.source_name = 'SampleAdapter'
        token1 = Store.get_value(@c.docname(:search_token))
        token1.should be_nil
        Store.get_data(@c.docname(:search)).should == {}
      end

    end

    describe "page methods" do
      it "should return diffs between master documents and client documents limited by page size" do
        Store.put_data(@s.docname(:md),@data).should == true
        Store.get_data(@s.docname(:md)).should == @data
        Store.put_value(@s.docname(:md_size),@data.size)
        @expected = {'1'=>@product1,'2'=>@product2}
        @cs.compute_page.should == [0,3,@expected]
        Store.get_value(@cs.client.docname(:cd_size)).to_i.should == 0
        Store.get_data(@cs.client.docname(:page)).should == @expected      
      end

      it "appends diff to the client document" do
        @cd = {'3'=>@product3}  
        Store.put_data(@c.docname(:cd),@cd)
        Store.get_data(@c.docname(:cd)).should == @cd

        @page = {'1'=>@product1,'2'=>@product2}
        @expected = {'1'=>@product1,'2'=>@product2,'3'=>@product3}

        Store.put_data(@c.docname(:cd),@page,true).should == true
        Store.get_data(@c.docname(:cd)).should == @expected
      end

      it "should return deleted objects in the client document" do
        Store.put_data(@s.docname(:md),@data).should == true
        Store.get_data(@s.docname(:md)).should == @data

        @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
        Store.put_data(@cs.client.docname(:cd),@cd)
        Store.get_data(@cs.client.docname(:cd)).should == @cd

        @expected = {'4'=>@product4}
        @cs.compute_deleted_page.should == @expected
        Store.get_data(@cs.client.docname(:delete_page)).should == @expected
      end  

      it "should delete objects from client document" do
        Store.put_data(@s.docname(:md),@data).should == true
        Store.get_data(@s.docname(:md)).should == @data

        @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
        Store.put_data(@cs.client.docname(:cd),@cd)
        Store.get_data(@cs.client.docname(:cd)).should == @cd

        Store.delete_data(@cs.client.docname(:cd),@cs.compute_deleted_page).should == true
        Store.get_data(@cs.client.docname(:cd)).should == @data 
      end

      it "should resend page if page exists and no token provided" do
        expected = {'1'=>@product1}
        set_test_data('test_db_storage',{'1'=>@product1,'2'=>@product2,'4'=>@product4})
        params = {'name' => 'iPhone'}
        @cs.send_cud(nil,params)
        token = @c.get_value(:page_token)
        @cs.send_cud.should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
          {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},{'insert' => expected}]
        @cs.send_cud(token).should == [{"version"=>ClientSync::VERSION},{"token"=>""}, 
          {"count"=>0}, {"progress_count"=>1}, {"total_count"=>1}, {}]
        Store.get_data(@cs.client.docname(:page)).should == {}              
        @c.get_value(:page_token).should be_nil
      end

      it "should send metadata with page" do
        expected = {'1'=>@product1}
        set_state('test_db_storage' => expected)
        metadata = "{\"foo\":\"bar\"}"
        mock_metadata_method([SampleAdapter]) do
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          result.should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
            {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},
            {'metadata'=>metadata,'insert'=>expected}]
          @c.get_value(:metadata_page).should == metadata
        end
      end

      it "should send metadata with resend page" do
        expected = {'1'=>@product1}
        set_state('test_db_storage' => expected)
        mock_metadata_method([SampleAdapter]) do
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          @cs.send_cud.should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
            {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},
            {'metadata'=>"{\"foo\":\"bar\"}",'insert'=>expected}] 
        end
      end

      it "should ack metadata page with ack token" do
        expected = {'1'=>@product1}
        set_state('test_db_storage' => expected)
        mock_metadata_method([SampleAdapter]) do
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          @cs.send_cud(token).should == [{"version"=>ClientSync::VERSION},{"token"=>""}, 
            {"count"=>0}, {"progress_count"=>1},{"total_count"=>1},{}]
          @c.get_value(:metadata_page).should be_nil
        end
      end

      it "shouldn't send schema-changed if client schema sha1 is nil" do
        expected = {'1'=>@product1}
        set_state('test_db_storage' => expected)
        mock_schema_method([SampleAdapter]) do
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          result.should ==  [{"version"=>ClientSync::VERSION},{"token"=>token}, 
            {"count"=>1}, {"progress_count"=>0},{"total_count"=>1},{'insert'=>expected}]
          @c.get_value(:schema_sha1).should == '8c148c8c1a66c7baf685c07d58bea360da87981b'
        end
      end

      it "should send schema-changed instead of page" do
        mock_schema_method([SampleAdapter]) do
          @c.put_value(:schema_sha1,'foo')
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          result.should ==  [{"version"=>ClientSync::VERSION},{"token"=>token}, 
            {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{'schema-changed'=>'true'}]
          @c.get_value(:schema_page).should == '8c148c8c1a66c7baf685c07d58bea360da87981b'
          @c.get_value(:schema_sha1).should == '8c148c8c1a66c7baf685c07d58bea360da87981b'
        end
      end

      it "should re-send schema-changed if no token sent" do
        mock_schema_method([SampleAdapter]) do
          @c.put_value(:schema_sha1,'foo')
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          @cs.send_cud.should ==  [{"version"=>ClientSync::VERSION},{"token"=>token}, 
            {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{'schema-changed'=>'true'}]
          @c.get_value(:schema_page).should == '8c148c8c1a66c7baf685c07d58bea360da87981b'
          @c.get_value(:schema_sha1).should == '8c148c8c1a66c7baf685c07d58bea360da87981b'
        end
      end

      it "should ack schema-changed with token" do
        mock_schema_method([SampleAdapter]) do
          @c.put_value(:schema_sha1,'foo')
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          @cs.send_cud(token).should ==  [{"version"=>ClientSync::VERSION},{"token"=>""}, 
            {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{}]
          @c.get_value(:schema_page).should be_nil
          @c.get_value(:schema_sha1).should == '8c148c8c1a66c7baf685c07d58bea360da87981b'
        end
      end

      it "should expire bulk data if schema changed" do
        docname = bulk_data_docname(@a.id,@u.id)
        data = BulkData.create(:name => docname,
          :state => :inprogress,
          :app_id => @a.id,
          :user_id => @u.id,
          :sources => [@s_fields[:name]])
        data.refresh_time = Time.now.to_i + 600
        mock_schema_method([SampleAdapter]) do
          @c.put_value(:schema_sha1,'foo')
          result = @cs.send_cud
          token = @c.get_value(:page_token)
          @cs.send_cud(token).should ==  [{"version"=>ClientSync::VERSION},{"token"=>""}, 
            {"count"=>0}, {"progress_count"=>0},{"total_count"=>0},{}]
          @c.get_value(:schema_page).should be_nil
          @c.get_value(:schema_sha1).should == '8c148c8c1a66c7baf685c07d58bea360da87981b'
          data = BulkData.load(docname)
          data.refresh_time.should <= Time.now.to_i
        end 
      end
    end

    describe "bulk data" do
      after(:each) do
        delete_data_directory
      end

      it "should create bulk data job user parition if none exists" do
        ClientSync.bulk_data(:user,@c).should == {:result => :wait}
        Resque.peek(:bulk_data).should == {"args"=>
          [{"data_name"=>File.join(@a_fields[:name],@u_fields[:login],@u_fields[:login])}], 
            "class"=>"Rhosync::BulkDataJob"}
      end

      it "should create bulk data job app partition if none exists and no partition sources" do
        ClientSync.bulk_data(:app,@c).should == {:result => :nop}
        Resque.peek(:bulk_data).should == nil
      end

      it "should create bulk data job app partition with partition sources" do
        @s.partition = :app
        ClientSync.bulk_data(:app,@c).should == {:result => :wait}
        Resque.peek(:bulk_data).should == {"args"=>
          [{"data_name"=>File.join(@a_fields[:name],@a_fields[:name])}], 
            "class"=>"Rhosync::BulkDataJob"}
      end

      it "should return bulk data url for completed bulk data user partition" do
        set_state('test_db_storage' => @data)
        ClientSync.bulk_data(:user,@c)
        BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,@u.id))
        ClientSync.bulk_data(:user,@c).should == {:result => :url,
          :url => BulkData.load(bulk_data_docname(@a.id,@u.id)).url}
        verify_result(
          "client:#{@a_fields[:name]}:#{@u_fields[:login]}:#{@c.id}:#{@s_fields[:name]}:cd" => @data,
          "source:#{@a_fields[:name]}:#{@u_fields[:login]}:#{@s_fields[:name]}:md" => @data,
          "source:#{@a_fields[:name]}:#{@u_fields[:login]}:#{@s_fields[:name]}:md_copy" => @data)
      end

      it "should escape bulk data url" do
        name = 'a b'
        data = BulkData.create(:name => bulk_data_docname(@a.id,name),
          :state => :inprogress,
          :app_id => @a.id,
          :user_id => name,
          :sources => [@s_fields[:name]])
        BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,name))
        data = BulkData.load(bulk_data_docname(@a.id,name))
        data.url.should match /a%20b/
        data.delete
      end

      it "should return bulk data url for completed bulk data app partition" do
        set_state('test_db_storage' => @data)
        @s.partition = :app
        ClientSync.bulk_data(:app,@c)
        BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,"*"))
        ClientSync.bulk_data(:app,@c).should == {:result => :url,
          :url => BulkData.load(bulk_data_docname(@a.id,"*")).url}
        verify_result(
          "client:#{@a_fields[:name]}:#{@u_fields[:login]}:#{@c.id}:#{@s_fields[:name]}:cd" => @data,
          "source:#{@a_fields[:name]}:__shared__:#{@s_fields[:name]}:md" => @data,
          "source:#{@a_fields[:name]}:__shared__:#{@s_fields[:name]}:md_copy" => @data)
      end

      it "should return bulk data url for completed bulk data with bulk_sync_only source" do
        set_state('test_db_storage' => @data)
        @s.sync_type = :bulk_sync_only
        ClientSync.bulk_data(:user,@c)
        BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,@u.id))
        ClientSync.bulk_data(:user,@c).should == {:result => :url,
          :url => BulkData.load(bulk_data_docname(@a.id,@u.id)).url}
        verify_result(
          "client:#{@a_fields[:name]}:#{@u_fields[:login]}:#{@c.id}:#{@s_fields[:name]}:cd" => {},
          "source:#{@a_fields[:name]}:#{@u_fields[:login]}:#{@s_fields[:name]}:md" => @data,
          "source:#{@a_fields[:name]}:#{@u_fields[:login]}:#{@s_fields[:name]}:md_copy" => {})
      end

      it "should create bulk data job if no file exists" do
        set_state('test_db_storage' => @data)
        Rhosync.blackberry_bulk_sync = true
        ClientSync.bulk_data(:user,@c)
        BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,@u.id))
        data = BulkData.load(bulk_data_docname(@a.id,@u.id))
        ClientSync.bulk_data(:user,@c).should == {:result => :url, :url => data.url}
        File.delete(data.dbfile)
        ClientSync.bulk_data(:user,@c).should == {:result => :wait}
        Resque.peek(:bulk_data).should == {"args"=>
          [{"data_name"=>bulk_data_docname(@a.id,@u.id)}], "class"=>"Rhosync::BulkDataJob"}
      end
     end
  end
end