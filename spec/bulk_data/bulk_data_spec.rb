require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkData" do
  include TestHelpers
  let(:test_app_name) { 'application' }  

  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end
    
  #it_should_behave_like "SourceAdapterHelper"
  before(:each) do # "RhosyncHelper"
    Store.create
    Store.db.flushdb
  end

  #  it_should_behave_like "DBObjectsHelper"
  before(:each) do
    @a_fields = { :name => test_app_name }
    # @a = App.create(@a_fields)
    @a = (App.load(test_app_name) || App.create(@a_fields))
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'Apple',
      :device_pin => 'abcd',
      :device_port => '3333',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.load(@s_fields[:name],@s_params)
    @s = Source.create(@s_fields,@s_params) if @s.nil?
    @s1 = Source.load('FixedSchemaAdapter',@s_params)
    @s1 = Source.create({:name => 'FixedSchemaAdapter'},@s_params) if @s1.nil?
    config = Rhosync.source_config["sources"]['FixedSchemaAdapter']
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources.members)
    @a.users << @u.id
  end


  
  after(:each) do
    delete_data_directory
  end
  
  it "should return true if bulk data is completed" do
    dbfile = create_datafile(File.join(@a.name,@u.id.to_s),@u.id.to_s)
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :completed,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.dbfile = dbfile 
    data.completed?.should == true
  end
  
  it "should return false if bulk data isn't completed" do
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.completed?.should == false
  end
  
  it "should expire_bulk_data from a source adapter" do
    adapter = SourceSync.new(@s).adapter
    time = Time.now.to_i + 10000
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]],
      :refresh_time => time)
    adapter.expire_bulk_data
    data = BulkData.load(bulk_data_docname(@a.id,@u.id))
    data.refresh_time.should <= Time.now.to_i
  end
  
  it "should enqueue sqlite db type" do
    BulkData.enqueue
    Resque.peek(:bulk_data).should == {"args"=>[{}], 
      "class"=>"Rhosync::BulkDataJob"}
  end
  
  it "should generate correct bulk data name for user partition" do
    BulkData.get_name(:user,@c.user_id).should == File.join(@a_fields[:name],@u_fields[:login],@u_fields[:login])
  end
  
  it "should generate correct bulk data name for app partition" do
    BulkData.get_name(:app,@c.user_id).should == 
      File.join(@a_fields[:name],@a_fields[:name])
  end
  
  it "should process_sources for bulk data" do
    current = Time.now.to_i
    @s.read_state.refresh_time = current
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.process_sources
    @s.read_state.refresh_time.should >= current + @s_fields[:poll_interval].to_i
  end
  
  it "should delete source masterdoc copy on delete" do
    set_state('test_db_storage' => @data)
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.process_sources
    verify_result(@s.docname(:md_copy) => @data)
    data.delete
    verify_result(@s.docname(:md_copy) => {},
      @s.docname(:md) => @data)
  end
end

def create_datafile(dir,name)
  dir = File.join(Rhosync.data_directory,dir)
  FileUtils.mkdir_p(dir)
  fname = File.join(dir,name+'.data')
  File.open(fname,'wb') {|f| f.puts ''}
  fname
end