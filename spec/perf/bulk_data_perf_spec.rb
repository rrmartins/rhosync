require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'perf_spec_helper')

describe "BulkData Performance" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  it_should_behave_like "PerfSpecHelper"
  
  after(:each) do
    delete_data_directory
  end
  
  it "should generate sqlite bulk data for 1000 objects (6000 attributes)" do
    start = start_timer
    @data = get_test_data(1000)
    start = lap_timer('generate data',start)
    set_state(@s.docname(:md) => @data)
    start = lap_timer('set_state masterdoc',start)
    data = BulkData.create(:name => BulkData.docname(@c.id),
      :state => :inprogress,
      :sources => [@s_fields[:name]])
    SqliteData.perform(:data_name => data.name)
    lap_timer('SqliteData.perform duration',start)
  end
  
end