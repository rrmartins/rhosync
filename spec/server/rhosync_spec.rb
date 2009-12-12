require File.join(File.dirname(__FILE__),'..','spec_helper')
require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'

set :environment, :test
set :run, false
set :views, File.join(File.dirname(__FILE__),'..','..','views')

require File.join(File.dirname(__FILE__),'..','..','rhosync.rb')

describe "Rhosync" do
  include Rack::Test::Methods
  include RhosyncStore
  
  it_should_behave_like "SourceAdapterHelper"

  def app
    @app ||= Sinatra::Application
  end
  
  it "should respond with 401 to /" do
    get '/'
    last_response.status.should == 401
  end

  it "should respond with 200 if logged in" do
    do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    get '/'
    last_response.status.should == 200
  end

  describe "auth routes" do
    it "should login user with correct username,password" do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
      last_response.should be_ok
    end
    
    it "should respond 401 for incorrect username or password" do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'wrongpass'
      last_response.status.should == 401
    end
  end
  
  describe "client management routes" do
    before(:each) do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    end
    
    it "should respond to clientcreate" do
      get "/apps/#{@a.name}/clientcreate"
      last_response.should be_ok
      last_response.body.should == { "client" => { "client_id" => "2" } }.to_json
      Client.with_key(2).user_id.should == 'testuser'
    end
    
    it "should respond to clientregister" do
      do_post "/apps/#{@a.name}/clientregister", "device_type" => "iPhone", "client_id" => @c.id
      last_response.should be_ok
      last_response.body.should == ''
      @c.device_type.should == 'iPhone'
      @c.id.should == 1
    end
    
    it "should respond to clientreset" do
      doc1 = Document.new('cd',@a.id,@u.id,@c.id,'source1')
      doc2 = Document.new('cd',@a.id,@u.id,@c.id,'source2')
      @store.put_data(doc1.get_key,@data)
      @store.put_data(doc2.get_key,@data)
      get "/apps/#{@a.name}/clientreset", :client_id => @c.id,:version => ClientSync::VERSION
      @store.get_data(doc1.get_key).should == {}
      @store.get_data(doc2.get_key).should == {}
    end
  end
  
  describe "source routes" do
    before(:each) do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    end
    
    it "should return 404 message with version < 3" do
      get "/apps/#{@a.name}",:source_name => @s.name,:version => 2
      last_response.status.should == 404
      last_response.body.should == "Server supports version 3 or higher of the protocol."
    end
    
    it "should post records for create" do
      @product1['_id'] = '1'
      params = {'create'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name,
        :version => ClientSync::VERSION}
      do_post "/apps/#{@a.name}", params
      last_response.should be_ok
      last_response.body.should == ''
      verify_result("test_create_storage" => {'1'=>@product1})
    end
    
    it "should post records for update" do
      params = {'update'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name,
        :version => ClientSync::VERSION}
      do_post "/apps/#{@a.name}", params
      last_response.should be_ok
      last_response.body.should == ''
      verify_result("test_update_storage" => {'1'=>@product1})
    end
    
    it "should post records for delete" do
      params = {'delete'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name,
        :version => ClientSync::VERSION}
      do_post "/apps/#{@a.name}", params
      last_response.should be_ok
      last_response.body.should == ''
      verify_result("test_delete_storage" => {'1'=>@product1})
    end
    
    it "should get inserts json" do
      cs = ClientSync.new(@s,@c,1)
      data = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',data)
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      last_response.should be_ok
      last_response.content_type.should == 'application/json'
      token = @store.get_value(cs.clientdoc.get_page_token_dockey)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>2},{"total_count"=>2},{'insert'=>data}]
    end
    
    it "should get inserts json and confirm token" do
      cs = ClientSync.new(@s,@c,1)
      data = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',data)
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      last_response.should be_ok
      token = @store.get_value(cs.clientdoc.get_page_token_dockey)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>2}, {"total_count"=>2},{'insert'=>data}]
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
        :version => ClientSync::VERSION
      last_response.should be_ok
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>''}, 
        {"count"=>0}, {"progress_count"=>2}, {"total_count"=>2},{}]
    end
    
    it "should get deletes json" do
      cs = ClientSync.new(@s,@c,1)
      data = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',data)
      
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      last_response.should be_ok
      token = @store.get_value(cs.clientdoc.get_page_token_dockey)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>2}, {"total_count"=>2},{'insert'=>data}]
      
      @store.flash_data('test_db_storage')
      @s.refresh_time = Time.now.to_i      
      
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
        :version => ClientSync::VERSION
      last_response.should be_ok
      token = @store.get_value(cs.clientdoc.get_page_token_dockey)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>0}, {"total_count"=>2},{'delete'=>data}]
    end
    
    it "should get search results" do
      sources = ['SampleAdapter']
      @store.put_data('test_db_storage',@data)
      params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
        :version => ClientSync::VERSION}
      get "/apps/#{@a.name}/search",params
      JSON.parse(last_response.body).should == [[{'version'=>ClientSync::VERSION},
        {'source'=>sources[0]},{'count'=>1},{'insert'=>{'1'=>@product1}}]]
    end
    
    it "should get search results with error" do
      sources = ['SampleAdapter']
      msg = "Error during search"
      error = set_test_data('test_db_storage',@data,msg,'search error')
      params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
        :version => ClientSync::VERSION}
      get "/apps/#{@a.name}/search",params
      JSON.parse(last_response.body).should == [[{'version'=>ClientSync::VERSION},
        {'source'=>sources[0]},{'search-error'=>{'search-error'=>{'message'=>msg}}}]]
    end
    
    it "should get multiple source search results" do
      @s_fields[:name] = 'SimpleAdapter'
      @s1 = Source.create(@s_fields)
      @store.put_data('test_db_storage',@data)
      sources = ['SimpleAdapter','SampleAdapter']
      params = {:client_id => @c.id,:sources => sources,:search => {'search' => 'bar'},
        :version => ClientSync::VERSION}
      get "/apps/#{@a.name}/search",params
      JSON.parse(last_response.body).should == [
        [{"version"=>ClientSync::VERSION}, {"source"=>"SimpleAdapter"}, 
         {"count"=>1}, {"insert"=>{'obj'=>{'foo'=>'bar'}}}],
        [{"version"=>ClientSync::VERSION}, {"source"=>"SampleAdapter"}, 
         {"count"=>1}, {"insert"=>{'1'=>@product1}}]]
    end
  end
end