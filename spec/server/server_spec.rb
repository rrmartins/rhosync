require File.join(File.dirname(__FILE__),'..','spec_helper')
require 'rubygems'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'

require File.join(File.dirname(__FILE__),'..','..','lib','rhosync','server.rb')

describe "Server" do
  it_should_behave_like "SourceAdapterHelper"
  
  include Rack::Test::Methods
  include Rhosync
  
  before(:each) do
    basedir = File.join(File.dirname(__FILE__),'..')
    Rhosync.bootstrap do |rhosync|
      rhosync.base_directory = basedir
      rhosync.vendor_directory = File.join(basedir,'..','vendor')
    end
    Server.set( 
      :environment => :test,
      :run => false,
      :secret => "secure!"
    )
    Server.use Rack::Static, :urls => ["/spec/data"], :root => File.join(basedir,'..')
  end

  def app
    @app ||= Server.new
  end
  
  it "should show status page" do
    get '/'
    last_response.body.match(Rhosync::VERSION)[0].should == Rhosync::VERSION
  end
  
  it "should login without app_name" do
    post "/login", "login" => @u_fields[:login], "password" => 'testpass'
    last_response.should be_ok
  end
  
  it "should respond with 401 to /apps/:app_name" do
    get "/apps/#{@a.name}"
    last_response.status.should == 401
  end
  
  it "should have default session secret" do
    Server.secret.should == "secure!"
  end
  
  it "should update session secret to default" do
    Server.set :secret, "<changeme>"
    Server.secret.should == "<changeme>"
    Logger.should_receive(:error).any_number_of_times.with(any_args())
    check_default_secret!("<changeme>")
    Server.set :secret, "secure!"
  end
  
  it "should complain about hsqldata.jar missing" do
    Rhosync.vendor_directory = 'missing'
    Logger.should_receive(:error).any_number_of_times.with(any_args())
    check_hsql_lib!
  end
  
  describe "helpers" do 
    before(:each) do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    end
    
    it "should return nil if params[:source_name] is missing" do
      get "/apps/#{@a.name}"
      last_response.status.should == 500
    end
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
    
    it "should create unknown user through delegated authentication" do
      do_post "/apps/#{@a.name}/clientlogin", "login" => 'newuser', "password" => 'testpass'
      User.is_exist?('newuser').should == true
      @a.users.members.sort.should == ['newuser','testuser']
    end
  end
  
  describe "client management routes" do
    before(:each) do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    end
    
    it "should respond to clientcreate" do
      get "/apps/#{@a.name}/clientcreate"
      last_response.should be_ok
      last_response.content_type.should == 'application/json'
      id = JSON.parse(last_response.body)['client']['client_id']
      id.length.should == 32
      last_response.body.should == { "client" => { "client_id" => id } }.to_json
      Client.load(id,{:source_name => '*'}).user_id.should == 'testuser'
    end
    
    it "should respond to clientregister" do
      do_post "/apps/#{@a.name}/clientregister", "device_type" => "iPhone", "client_id" => @c.id
      last_response.should be_ok
      last_response.body.should == ''
      @c.device_type.should == 'iPhone'
      @c.id.length.should == 32
    end
    
    it "should respond to clientreset" do
      set_state(@c.docname(:cd) => @data)
      get "/apps/#{@a.name}/clientreset", :client_id => @c.id,:version => ClientSync::VERSION
      verify_result(@c.docname(:cd) => {})
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
      token = @c.get_value(:page_token)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>0},{"total_count"=>2},{'insert'=>data}]
    end
    
    it "should get inserts json and confirm token" do
      cs = ClientSync.new(@s,@c,1)
      data = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',data)
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
      last_response.should be_ok
      token = @c.get_value(:page_token)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>0}, {"total_count"=>2},{'insert'=>data}]
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
      token = @c.get_value(:page_token)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>0}, {"total_count"=>2},{'insert'=>data}]
      
      Store.flash_data('test_db_storage')
      @s.read_state.refresh_time = Time.now.to_i      
      
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token,
        :version => ClientSync::VERSION
      last_response.should be_ok
      token = @c.get_value(:page_token)
      JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
        {"count"=>2}, {"progress_count"=>0}, {"total_count"=>0},{'delete'=>data}]
    end
    
    it "should get search results" do
      sources = ['SampleAdapter']
      cs = ClientSync.new(@s,@c,1)
      Store.put_data('test_db_storage',@data)
      params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
        :version => ClientSync::VERSION}
      get "/apps/#{@a.name}/search",params
      last_response.content_type.should == 'application/json'
      token = @c.get_value(:search_token)
      JSON.parse(last_response.body).should == [[{'version'=>ClientSync::VERSION},{'search_token'=>token},
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
      @s1 = Source.create(@s_fields,@s_params)
      Store.put_data('test_db_storage',@data)
      sources = ['SimpleAdapter','SampleAdapter']
      params = {:client_id => @c.id,:sources => sources,:search => {'search' => 'bar'},
        :version => ClientSync::VERSION}
      get "/apps/#{@a.name}/search",params
      @c.source_name = 'SimpleAdapter'
      token1 = @c.get_value(:search_token)
      @c.source_name = 'SampleAdapter'
      token = @c.get_value(:search_token)
      JSON.parse(last_response.body).should == [
        [{"version"=>ClientSync::VERSION},{'search_token'=>token1},{"source"=>"SimpleAdapter"}, 
         {"count"=>1}, {"insert"=>{'obj'=>{'foo'=>'bar'}}}],
        [{"version"=>ClientSync::VERSION},{'search_token'=>token},{"source"=>"SampleAdapter"}, 
         {"count"=>1}, {"insert"=>{'1'=>@product1}}]]
    end
  end
    
  describe "bulk data routes" do
    before(:each) do
      do_post "/apps/#{@a.name}/clientlogin", "login" => @u.login, "password" => 'testpass'
    end
    
    after(:each) do
     delete_data_directory
    end
  
    it "should make initial bulk data request and receive wait" do
      set_state('test_db_storage' => @data)
      get "/apps/#{@a.name}/bulk_data", :partition => :user, :client_id => @c.id
      last_response.should be_ok
      last_response.body.should == {:result => :wait}.to_json
    end
    
    it "should receive url when bulk data is available" do
      set_state('test_db_storage' => @data)
      get "/apps/#{@a.name}/bulk_data", :partition => :user, :client_id => @c.id
      BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,@u.id))
      get "/apps/#{@a.name}/bulk_data", :partition => :user, :client_id => @c.id
      last_response.should be_ok
      last_response.body.should == {:result => :url, 
        :url => BulkData.load(bulk_data_docname(@a.id,@u.id)).dbfile}.to_json
      validate_db_by_name(JSON.parse(last_response.body)["url"],@data)
    end
    
    it "should download bulk data file" do
      set_state('test_db_storage' => @data)
      get "/apps/#{@a.name}/bulk_data", :partition => :user, :client_id => @c.id
      BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,@u.id))
      get "/apps/#{@a.name}/bulk_data", :partition => :user, :client_id => @c.id
      get "/spec/data/#{@a.name}/#{@u.id}/#{JSON.parse(last_response.body)["url"].split('/').last}"
      last_response.should be_ok
      File.open('test.data','wb') {|f| f.puts last_response.body}
      validate_db_by_name('test.data',@data)
      File.delete('test.data')
    end
  
    it "should receive nop when no sources are available for partition" do
      set_state('test_db_storage' => @data)
      get "/apps/#{@a.name}/bulk_data", :partition => :app, :client_id => @c.id
      last_response.should be_ok
      last_response.body.should == {:result => :nop}.to_json
    end
  end
end