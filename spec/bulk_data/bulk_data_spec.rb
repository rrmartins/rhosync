require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkData" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  after(:each) do
    delete_data_directory
  end
  
  it "should docname of bulk data for client" do
    BulkData.docname(@c.id).should == File.join(@a.name,@u.id.to_s,@c.id.to_s+'.data')
  end
  
  it "should return true if bulk data exists" do
    create_datafile(File.join(@a.name,@u.id.to_s),@c.id.to_s)
    BulkData.create(:name => BulkData.docname(@c.id),
      :state => :completed,
      :sources => [@s_fields[:name]])
    BulkData.exists?({:dbtype => :sqlite, 
      :client_id => @c.id,
      :sources => [@s_fields[:name]]}).should == true
  end
  
  it "should return false if bulk data doesn't exist" do
    BulkData.create(:name=>BulkData.docname(@c.id),
      :state => :inprogress,
      :sources => [@s_fields[:name]])
    BulkData.exists?({:dbtype => :sqlite, 
      :client_id => @c.id,
      :sources => [@s_fields[:name]]}).should == false
  end
  
  it "should raise error on unsupported dbtype" do
    lambda { BulkData.enqueue(:dbtype => :mysql) }.should raise_error(UnsupportedDbType, 'Unsupported DB Type')
  end
  
  it "should enqueue sqlite db type" do
    BulkData.enqueue(:dbtype => :sqlite)
    Resque.peek(:bulk_data).should == {"args"=>[{"dbtype"=>"sqlite"}], 
      "class"=>"RhosyncStore::SqliteData"}
  end
end

def create_datafile(dir,name)
  dir = File.join(RhosyncStore.data_directory,dir)
  FileUtils.mkdir_p(dir)
  File.open(File.join(dir,name+'.data'),'wb') {|f| f.puts ''}
end