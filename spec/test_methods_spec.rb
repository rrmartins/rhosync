require 'rhosync/test_methods'
require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "TestMethods" do
  # The module we're testing
  include Rhosync::TestMethods

  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    before(:each) do
      Rhosync.bootstrap(get_testapp_path)
      setup_test_for(SampleAdapter,'user1')
    end

    it "should setup_test_for an adapter and user" do
      @u.is_a?(User).should == true
      @s.is_a?(Source).should == true
      @ss.is_a?(SourceSync).should == true
      @ss.adapter.is_a?(SampleAdapter).should == true
      @u.login.should == 'user1'
      @s.name.should == 'SampleAdapter'
      @c.id.size.should == 32
      @c.device_pin.should == 'abcd'
      @c.device_port.should == '3333'
      @c.device_type.should == 'Apple'
      @c.user_id.should == 'user1'
      @c.app_id.should == 'application'
    end

    it "should include test_query helper" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      test_query.should == expected
    end
    
    it "should include test_query helper when pass through" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      @s.pass_through = 'true'
      test_query.should == expected
    end

    it "should include query_errors helper" do
      expected =  {"query-error"=>{'message'=>'failed'}}
      set_state(@s.docname(:errors) => expected)
      query_errors.should == expected
    end

    it "should include test_create helper" do
      @product4['link'] = 'test link'
      test_create(@product4).should == 'backend_id'
    end
    
    it "should include test_create helper when pass through" do
      @s.pass_through = 'true'
      p test_create(@product4)
      test_create(@product4).should == {'processed' => ["temp-id"]}.to_json
    end

    it "should include create_errors helper" do
      expected =  {"create-error"=>{'message'=>'failed'}}
      set_state(@c.docname(:create_errors) => expected)
      create_errors.should == expected
    end

    it "should include test_update helper" do
      record = {'4'=> { 'price' => '199.99' }}
      test_update(record)
      verify_result(@c.docname(:update) => {})
    end
    
    it "should include test_update helper when pass through" do
      record = {'4'=> { 'price' => '199.99' }}
      @s.pass_through = 'true'
      test_update(record).should == {'processed' => ["4"]}.to_json
      verify_result(@c.docname(:update) => {})
    end

    it "should include update_errors helper" do
      expected =  {"update-error"=>{'message'=>'failed'}}
      set_state(@c.docname(:update_errors) => expected)
      update_errors.should == expected
    end

    it "should include test_delete helper" do
      record = {'4'=> { 'price' => '199.99' }}
      test_delete(record)
      verify_result(@c.docname(:delete) => {})
    end
    
    it "should include test_delete helper when pass through" do
      record = {'4'=> { 'price' => '199.99' }}
      @s.pass_through = 'true'
      test_delete(record).should == {'processed' => ["4"]}.to_json
      verify_result(@c.docname(:delete) => {})
    end

    it "should include delete_errors helper" do
      expected =  {"delete-error"=>{'message'=>'failed'}}
      set_state(@c.docname(:delete_errors) => expected)
      delete_errors.should == expected
    end

    it "should include md helper" do
      set_state(@s.docname(:md) => @data)
      md.should == @data
    end

    it "should include cd helper" do
      set_state(@c.docname(:cd) => @data)
      cd.should == @data
    end
  end
end