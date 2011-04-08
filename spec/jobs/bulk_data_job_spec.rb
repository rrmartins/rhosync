require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkDataJob" do
  include TestHelpers
  let(:test_app_name) { 'application' }

  let(:source) { 'Product' }
  let(:user_id) { 5 }
  let(:client_id)  { 1 }
  let(:product1) { {'name' => 'iPhone', 'brand' => 'Apple', 'price' => '199.99'} }
  let(:product2) { {'name' => 'G2', 'brand' => 'Android', 'price' => '99.99'} }
  let(:product3) { {'name' => 'Fuze', 'brand' => 'HTC', 'price' => '299.99'} }  
  let(:product4) { {'name' => 'Droid', 'brand' => 'Android', 'price' => '249.99'} }
  let(:products)     { {'1' => product1,'2' => product2,'3'=> product3} }

  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end
  
  before(:each) do # "RhosyncHelper"
    Store.create
    Store.db.flushdb
  end

  #   it_should_behave_like "DBObjectsHelper"
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
  
  
  before(:each) do
    Rhosync.blackberry_bulk_sync = true
  end
  
  after(:each) do
    delete_data_directory
  end
  
  it "should create bulk data files from master document" do
    set_state('test_db_storage' => products)
    docname = bulk_data_docname(@a.id,@u.id)
    expected = { @s_fields[:name] => products,
      'FixedSchemaAdapter' => products
    }
    data = BulkData.create(:name => docname,
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name], 'FixedSchemaAdapter'])
    BulkDataJob.perform("data_name" => data.name)
    data = BulkData.load(docname)
    data.completed?.should == true
    verify_result(@s.docname(:md) => products,@s.docname(:md_copy) => products)
    validate_db(data,expected).should == true
    File.exists?(data.dbfile+'.rzip').should == true
    File.exists?(data.dbfile+'.gzip').should == true
    File.exists?(data.dbfile+'.hsqldb.data').should == true
    File.exists?(data.dbfile+'.hsqldb.data.gzip').should == true
    File.exists?(data.dbfile+'.hsqldb.script').should == true
    File.exists?(data.dbfile+'.hsqldb.properties').should == true
    path = File.join(File.dirname(data.dbfile),'tmp')
    FileUtils.mkdir_p path
    unzip_file("#{data.dbfile}.rzip",path)
    data.dbfile = File.join(path,File.basename(data.dbfile))
    validate_db(data,expected).should == true
  end
  
  it "should not create hsql db files if blackberry_bulk_sync is disabled" do
    Rhosync.blackberry_bulk_sync = false
    set_state('test_db_storage' => products)
    docname = bulk_data_docname(@a.id,@u.id)
    data = BulkData.create(:name => docname,
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    BulkDataJob.perform("data_name" => data.name)
    data = BulkData.load(docname)
    data.completed?.should == true
    verify_result(@s.docname(:md) => products,@s.docname(:md_copy) => products)
    validate_db(data,@s.name => products).should == true
    File.exists?(data.dbfile+'.hsqldb.script').should == false
    File.exists?(data.dbfile+'.hsqldb.properties').should == false
  end

  it "should create sqlite data with source metadata" do
    set_state('test_db_storage' => products)
    mock_metadata_method([SampleAdapter]) do
      docname = bulk_data_docname(@a.id,@u.id)
      data = BulkData.create(:name => docname,
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => @u.id,
        :sources => [@s_fields[:name]])
      BulkDataJob.perform("data_name" => data.name)
      data = BulkData.load(docname)
      data.completed?.should == true
      verify_result(@s.docname(:md) => products,
        @s.docname(:metadata) => {'foo'=>'bar'}.to_json,
        @s.docname(:md_copy) => products)
      validate_db(data,@s.name => products).should == true
    end
  end
  
  it "should create sqlite data with source schema" do
    set_state('test_db_storage' => products)
    mock_schema_method([SampleAdapter]) do
      docname = bulk_data_docname(@a.id,@u.id)
      data = BulkData.create(:name => docname,
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => @u.id,
        :sources => [@s_fields[:name]])
      BulkDataJob.perform("data_name" => data.name)
      data = BulkData.load(docname)
      data.completed?.should == true
      verify_result(@s.docname(:md) => products,
        @s.docname(:schema) => "{\"property\":{\"brand\":\"string\",\"name\":\"string\"},\"version\":\"1.0\"}",
        @s.docname(:md_copy) => products)
      validate_db(data,@s.name => products).should == true
    end
  end
  
  it "should raise exception if hsqldata fails" do
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    lambda { BulkDataJob.create_hsql_data_file(data,Time.now.to_i.to_s) 
      }.should raise_error(Exception,"Error running hsqldata")
  end
  
  it "should delete bulk data if exception is raised" do
    lambda { BulkDataJob.perform("data_name" => 'broken') }.should raise_error(Exception)
    Store.db.keys('bulk_data*').should == []
  end
  
  it "should delete bulk data if exception is raised" do
    data = BulkData.create(:name => bulk_data_docname('broken',@u.id),
      :state => :inprogress,
      :app_id => 'broken',
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    lambda { BulkDataJob.perform("data_name" => data.name) }.should raise_error(Exception)
    Store.db.keys('bulk_data*').should == []
  end
end