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
    verify_result(@s.docname(:errors) => {'login-error'=>{'message'=>msg}})
  end
  
  it "should raise SourceAdapterLogoffException if logoff fails" do
    msg = "Error logging off"
    Logger.should_receive(:error).with("SourceAdapter raised logoff exception: #{msg}")
    set_test_data('test_db_storage',{},msg,'logoff error')
    @ss.process
    verify_result(@s.docname(:errors) => {'logoff-error'=>{'message'=>msg}})
  end
  
  it "should hold on read on subsequent call of process" do
    expected = {'1'=>@product1}
    Store.put_data('test_db_storage',expected)
    @ss.process
    Store.put_data('test_db_storage',{'2'=>@product2})
    @ss.process
    verify_result(@s.docname(:md) => expected)   
  end
  
  it "should read on every subsequent call of process" do
    expected = {'2'=>@product2}
    @s.poll_interval = 0
    Store.put_data('test_db_storage',{'1'=>@product1})
    @ss.process
    Store.put_data('test_db_storage',expected)
    @ss.process
    verify_result(@s.docname(:md) => expected)    
  end

  it "should never call read on any call of process" do
    @s.poll_interval = -1
    Store.put_data('test_db_storage',{'1'=>@product1})
    @ss.process
    verify_result(@s.docname(:md) => {})
  end
    
  describe "methods" do
    
    it "should process source adapter" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      @ss.process
      verify_result(@s.docname(:md) => expected)
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
        set_state(@c.docname(:create) => {'2'=>@product2},
          @s.docname(:create) => [@c.id])
        @ss.create
        verify_result(@s.docname(:create) => [],
          @c.docname(:create_errors) => {},
          @c.docname(:create_links) => {},
          @c.docname(:create) => {})
      end
    
      it "should do create where adapter.create returns object link" do
        @product4['link'] = 'test link'
        set_state(@c.docname(:create) => {'4'=>@product4},
          @s.docname(:create) => [@c.id])
        @ss.create
        verify_result(@c.docname(:create_errors) => {},
          @c.docname(:create_links) => {'4'=>{'l'=>'backend_id'}},
          @c.docname(:create) => {},
          @s.docname(:create) => [])
      end
    
      it "should raise exception on adapter.create" do
        msg = "Error creating record"
        data = add_error_object({'4'=>@product4,'2'=>@product2},msg)
        set_state({@c.docname(:create) => data,
          @s.docname(:create) => [@c.id]})
        @ss.create
        verify_result(@c.docname(:create_errors) => 
          {"#{ERROR}-error"=>{"message"=>msg},ERROR=>data[ERROR]})
      end
    end
    
    describe "update" do
      it "should do update with no errors" do
        set_state(@c.docname(:update) => {'4'=> { 'price' => '199.99' }},
          @s.docname(:update) => [@c.id])
        @ss.update
        verify_result(@s.docname(:update) => [],
          @c.docname(:update_errors) => {},
          @c.docname(:update) => {})
      end
      
      it "should do update with errors" do
        msg = "Error updating record"
        data = add_error_object({'4'=> { 'price' => '199.99' }},msg)
        set_state(@c.docname(:update) => data,
          @s.docname(:update) => [@c.id])
        @ss.update
        verify_result(@c.docname(:update_errors) =>
          {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data[ERROR]},
            @c.docname(:update) => {'4'=> { 'price' => '199.99'}},
          @s.docname(:update) => [@c.id.to_s])
      end
    end
    
    describe "delete" do
      it "should do delete with no errors" do
        set_state(@c.docname(:delete) => {'4'=>@product4},
          @s.docname(:delete) => [@c.id],
          @s.docname(:md) => {'4'=>@product4,'3'=>@product3},
          @c.docname(:cd) => {'4'=>@product4,'3'=>@product3})
        @ss.delete
        verify_result(@c.docname(:delete_errors) => {},
          @s.docname(:delete) => [],
          @s.docname(:md) => {'3'=>@product3},
          @c.docname(:cd) => {'3'=>@product3},
          @c.docname(:delete) => {})
      end
      
      it "should do delete with errors" do
        msg = "Error delete record"
        data = add_error_object({'2'=>@product2},msg)
        set_state(@c.docname(:delete) => data,
          @s.docname(:delete) => [@c.id])
        @ss.delete
        verify_result(@c.docname(:delete_errors) => 
          {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data[ERROR]},
            @c.docname(:delete) => {'2'=>@product2},
            @s.docname(:delete) => [@c.id.to_s])
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
    
    describe "app-level partitioning" do
      it "should create app-level masterdoc with '__shared__' docname" do
        @s1 = Source.load(@s_fields[:name],@s_params)
        @s1.partition = :app
        @ss1 = SourceSync.new(@s1)
        expected = {'1'=>@product1,'2'=>@product2}
        set_state('test_db_storage' => expected)
        @ss1.process
        verify_result("source:#{@a_fields[:name]}:__shared__:#{@s_fields[:name]}:md" => expected)
        Store.db.keys("read_state:#{@a_fields[:name]}:__shared__*").sort.should ==
          [ "read_state:rhotestapp:__shared__:SampleAdapter:refresh_time",
            "read_state:rhotestapp:__shared__:SampleAdapter:rho__id"]
      end
    end
    
    def verify_read_operation(operation)
      expected = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',expected)
      Store.put_data(@s.docname(:errors),
        {"#{operation}-error"=>{'message'=>'failed'}},true)
      if operation == 'query'
        @ss.read.should == true
        verify_result(@s.docname(:md) => expected, 
          @s.docname(:errors) => {})
      else
        @ss.search(@c.id).should == true  
        verify_result(@c.docname(:search) => expected,
          @c.docname(:search_errors) => {})
      end
    end
    
    def verify_read_operation_with_error(operation)
      msg = "Error during #{operation}"
      Logger.should_receive(:error).with("SourceAdapter raised #{operation} exception: #{msg}")
      set_test_data('test_db_storage',{},msg,"#{operation} error")
      if operation == 'query'
        @ss.read.should == true
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
      else
        @ss.search(@c.id).should == true
        verify_result(@c.docname(:search) => {}, 
          @c.docname(:search_errors) => {'search-error'=>{'message'=>msg}})
      end
    end
  end
end