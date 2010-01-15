require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkData" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  after(:each) do
    delete_data_directory
  end
  
  it "should return true if bulk data exists" do
    create_datafile(File.join(@a.name,@u.id.to_s),@c.id.to_s)
    BulkData.create(:name => bulk_data_docname(@a.id,@u.id,@c.id),
      :state => :completed,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    BulkData.exists?({:name => bulk_data_docname(@a.id,@u.id,@c.id),
      :sources => [@s_fields[:name]]}).should == true
  end
  
  it "should return false if bulk data doesn't exist" do
    BulkData.create(:name => bulk_data_docname(@a.id,@u.id,@c.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    BulkData.exists?({:name => bulk_data_docname(@a.id,@u.id,@c.id),
      :sources => [@s_fields[:name]]}).should == false
  end
  
  it "should enqueue sqlite db type" do
    BulkData.enqueue
    Resque.peek(:bulk_data).should == {"args"=>[{}], 
      "class"=>"RhosyncStore::BulkDataJob"}
  end
end

def create_datafile(dir,name)
  dir = File.join(RhosyncStore.data_directory,dir)
  FileUtils.mkdir_p(dir)
  File.open(File.join(dir,name+'.data'),'wb') {|f| f.puts ''}
end