require 'sqlite3'
require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkDataJob" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  after(:each) do
    delete_data_directory
  end
  
  it "should create sqlite data file from master document" do
    set_state('test_db_storage' => @data)
    docname = bulk_data_docname(@a.id,@u.id,@c.id)
    data = BulkData.create(:name => docname,
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    BulkDataJob.perform(:data_name => data.name)
    data = BulkData.load(docname)
    data.completed?.should == true
    verify_result(@s.docname(:md) => @data,@s.docname(:md_copy) => @data)
    validate_db(data,@data).should == true
    File.exists?(data.dbfile+'.hsqldb.script').should == true
    File.exists?(data.dbfile+'.hsqldb.properties').should == true
  end
  
  def validate_db(bulk_data,data)
    db = SQLite3::Database.new(bulk_data.dbfile)
    db.execute("select * from object_values").each do |row|
      object = data[row[2]]
      return false if object.nil? or object[row[1]] != row[3] or row[0] != @s.source_id.to_s
      object.delete(row[1])
      data.delete(row[2]) if object.empty?
    end  
    data.empty?
  end
end