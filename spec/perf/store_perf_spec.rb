require File.join(File.dirname(__FILE__),'perf_spec_helper')

describe "Rhosync Performance" do
  it_behaves_like "SharedRhosyncHelper" do
    it "should process get/put for 1000 records (6000 elements)" do
      @data = get_test_data(1000)
      start = start_timer
      Store.put_data('mdoc',@data).should == true
      start = lap_timer('put_data duration',start)
      Store.get_data('mdoc').should == @data
      lap_timer('get_data duration',start)
    end

    it "should process single attribute update 1000-record doc" do
      @data = get_test_data(1000)
      @data1 = get_test_data(1000)
      @data1['950']['Phone1'] = 'This is changed'
      expected = {'950' => {'Phone1' => 'This is changed'}}
      Store.put_data('mdoc',@data).should == true
      Store.put_data('cdoc',@data1).should == true
      start = start_timer
      Store.get_diff_data('mdoc','cdoc').should == [expected,1]
      lap_timer('get_diff_data duration', start)
    end
  end

end