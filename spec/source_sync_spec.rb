require File.join(File.dirname(__FILE__),'spec_helper')

describe "SourceSync" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @ss = SourceSync.new(@s)
  end
  
  it "should create SourceSync" do
    @ss.adapter.is_a?(SampleAdapter).should == true
  end
  
  it "should fail to create SourceSync with InvalidArgumentError" do
    lambda { SourceSync.new(nil) }.should raise_error(InvalidArgumentError, 'Invalid source')
  end
  
  it "should raise SourceAdapterLoginException if login fails" do
    msg = "Error logging in"
    Logger.should_receive(:error).with("SourceAdapter raised login exception: #{msg}")
    @u.login = nil
    @ss = SourceSync.new(@s)
    @ss.process
    verify_result(@s.document.get_source_errors_dockey => {'login-error'=>{'message'=>msg}})
  end
  
  it "should raise SourceAdapterLogoffException if logoff fails" do
    msg = "Error logging off"
    Logger.should_receive(:error).with("SourceAdapter raised logoff exception: #{msg}")
    set_test_data('test_db_storage',{},msg,'logoff error')
    @ss.process
    verify_result(@s.document.get_source_errors_dockey => {'logoff-error'=>{'message'=>msg}})
  end
  
  it "should hold on read on subsequent call of process" do
    expected = {'1'=>@product1}
    @a.store.put_data('test_db_storage',expected)
    @ss.process
    @a.store.put_data('test_db_storage',{'2'=>@product2})
    @ss.process
    verify_result(@s.document.get_key => expected)   
  end
  
  it "should read on every subsequent call of process" do
    expected = {'2'=>@product2}
    @s.poll_interval = 0
    @a.store.put_data('test_db_storage',{'1'=>@product1})
    @ss.process
    @a.store.put_data('test_db_storage',expected)
    @ss.process
    verify_result(@s.document.get_key => expected)    
  end

  it "should never call read on any call of process" do
    @s.poll_interval = -1
    @a.store.put_data('test_db_storage',{'1'=>@product1})
    @ss.process
    verify_result(@s.document.get_key => {})
  end
    
  describe "methods" do
    before(:each) do
      @clientdoc = Document.new('cd',@a.id,@s.user.id,@c.id,@s.name)
    end
    
    it "should process source adapter" do
      expected = {'1'=>@product1,'2'=>@product2}
      @a.store.put_data('test_db_storage',expected)
      @ss.process
      verify_result(@s.document.get_key => expected)
    end
    
    it "should call methods in source adapter" do
      expected = {'1'=>@product1,'2'=>@product2}
      @ss.adapter.should_receive(:login).once.with(no_args()).and_return(true)
      @ss.adapter.should_receive(:query).once.with(no_args()).and_return(expected)
      @ss.adapter.should_receive(:sync).once.with(no_args()).and_return(true)
      @ss.adapter.should_receive(:logoff).once.with(no_args()).and_return(nil)
      @ss.process
    end
    
    describe "create" do
      it "should do create where adapter.create returns nil" do
        set_test_data(@s.document.get_create_dockey,{'2'=>@product2})
        @ss.create.should == true
        verify_result(@s.document.get_create_errors_dockey => {},
          @s.document.get_create_links_dockey => {},
          @s.document.get_create_dockey => {})
      end
    
      it "should do create where adapter.create returns object link" do
        @product4['link'] = 'test link'
        set_test_data(@s.document.get_create_dockey,{'4'=>@product4})
        @ss.create.should == true
        verify_result(@s.document.get_create_errors_dockey => {},
          @clientdoc.get_create_links_dockey => {'4'=>{'l'=>'backend_id'}},
          @s.document.get_create_dockey => {})
      end
    
      it "should raise exception on adapter.create" do
        msg = "Error creating record"
        created_data = set_test_data(@s.document.get_create_dockey,{'4'=>@product4,'2'=>@product2},msg)
        @ss.create.should == true
        verify_result(@clientdoc.get_create_errors_dockey => 
          {"#{ERROR}-error"=>{"message"=>msg},ERROR=>created_data[ERROR]})
      end
    end
    
    describe "update" do
      it "should do update with no errors" do
        set_test_data(@s.document.get_update_dockey,{'4'=> { 'price' => '199.99' }})
        @ss.update.should == true
        verify_result(@s.document.get_update_errors_dockey => {},
          @s.document.get_update_dockey => {})
      end
      
      it "should do update with errors" do
        msg = "Error updating record"
        data = set_test_data(@s.document.get_update_dockey,{'4'=> { 'price' => '199.99' }},msg)
        @ss.update.should == true
        verify_result(@clientdoc.get_update_errors_dockey =>
          {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data[ERROR]},
            @s.document.get_update_dockey => {'4'=> { 'price' => '199.99', 
            'rhomobile.rhoclient' => @c.id.to_s }})
      end
    end
    
    describe "delete" do
      it "should do delete with no errors" do
        set_state(@s.document.get_delete_dockey => add_client_id({'4'=>@product4}),
          @s.document.get_key => {'4'=>@product4,'3'=>@product3},
          @clientdoc.get_key => {'4'=>@product4,'3'=>@product3})
        @ss.delete.should == true
        verify_result(@s.document.get_delete_errors_dockey => {},
          @s.document.get_delete_dockey => {},
          @s.document.get_key => {'3'=>@product3},
          @clientdoc.get_key => {'3'=>@product3})
      end
      
      it "should do delete with errors" do
        msg = "Error deleting record"
        data = set_test_data(@s.document.get_delete_dockey,{'4'=>@product4,'2'=>@product2},msg)
        @ss.delete.should == true
        verify_result(@clientdoc.get_delete_errors_dockey => 
          {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data.delete(ERROR)},
            @s.document.get_delete_dockey => data)
      end
    end
    
    describe "query" do
      it "should do query with no exception" do
        verify_read_operation('query')
      end
      
      it "should do query with exception raised" do
        verify_read_operation_with_error('query')
      end
    end
    
    describe "search" do
      it "should do search with no exception" do
        verify_read_operation('search')
      end
      
      it "should do search with exception raised" do
        verify_read_operation_with_error('search')
      end
    end
    
    def verify_read_operation(operation)
      expected = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',expected)
      @s.app.store.put_data(@s.document.get_source_errors_dockey,
                            {"#{operation}-error"=>{'message'=>'failed'}},true)
      if operation == 'query'
        @ss.read.should == true
        verify_result(@s.document.get_key => expected, 
          @s.document.get_source_errors_dockey => {})
      else
        @ss.search(@c.id).should == true  
        verify_result(@clientdoc.get_search_dockey => expected,
          @clientdoc.get_search_errors_dockey => {})
      end
    end
    
    def verify_read_operation_with_error(operation)
      msg = "Error during #{operation}"
      Logger.should_receive(:error).with("SourceAdapter raised #{operation} exception: #{msg}")
      set_test_data('test_db_storage',{},msg,"#{operation} error")
      if operation == 'query'
        @ss.read.should == true
        verify_result(@s.document.get_key => {},
          @s.document.get_source_errors_dockey => {'query-error'=>{'message'=>msg}})
      else
        @ss.search(@c.id).should == true
        verify_result(@clientdoc.get_search_dockey => {}, 
          @clientdoc.get_search_errors_dockey => {'search-error'=>{'message'=>msg}})
      end
    end
  end
end