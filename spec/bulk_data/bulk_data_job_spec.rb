require 'sqlite3'
require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkDataJob" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  after(:each) do
    delete_data_directory
  end
  
  it "should create sqlite data file from master document" do
    set_state(@s.docname(:md) => @data)
    data = BulkData.create(:name => BulkData.docname(@c.id),
      :state => :inprogress,
      :sources => [@s_fields[:name]])
    BulkDataJob.perform(:data_name => data.name)
    BulkData.exists?({:client_id => @c.id,
      :sources => [@s_fields[:name]]}).should == true
    validate_db(data.name,@data).should == true
    File.exists?(get_db_filename(data.name)+'.hsqldb.script').should == true
    File.exists?(get_db_filename(data.name)+'.hsqldb.properties').should == true
  end
  
  def validate_db(dbname,data)
    db = SQLite3::Database.new(get_db_filename(dbname))
    db.execute("select * from object_values").each do |row|
      object = data[row[2]]
      return false if object.nil? or object[row[1]] != row[3]
      object.delete(row[1])
      data.delete(row[2]) if object.empty?
    end  
    data.empty?
  end
  
  def get_db_filename(dbname)
    File.join(RhosyncStore.data_directory,dbname)
  end
end