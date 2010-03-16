require File.join(File.dirname(__FILE__),'spec_helper')

describe "SourceJob" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  it "should perform process_query" do
    set_state('test_db_storage' => @data)  
    SourceJob.perform('query',@s.id,@s.app_id,@s.user_id,nil,nil)
    verify_result(@s.docname(:md) => @data,
      @s.docname(:md_size) => @data.size.to_s)
  end
  
  it "should perform process_cud" do
    expected = {'backend_id'=>@product1}
    @product1['link'] = 'abc'
    set_state(@c.docname(:create) => {'1'=>@product1})
    SourceJob.perform('cud',@s.id,@s.app_id,@s.user_id,@c.id,nil)
    verify_result(@s.docname(:md) => expected,
      @s.docname(:md_size) => expected.size.to_s,
      @c.docname(:cd) => expected,
      @c.docname(:cd_size) => expected.size.to_s,
      @c.docname(:create) => {})
  end
end