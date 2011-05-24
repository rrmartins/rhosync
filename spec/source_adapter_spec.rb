require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

class Rhosync::SourceAdapter 
  def inject_result(result) 
    @result = result
  end
  
  def inject_tmpdoc(docname)
    @tmp_docname = docname
    @stash_size = 0
  end
end

describe "SourceAdapter" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    before(:each) do
      @s = Source.load(@s_fields[:name],@s_params)
      @s.name = 'SimpleAdapter'
      @sa = SourceAdapter.create(@s)
    end

    it "should create SourceAdapter with source" do
      @sa.class.name.should == @s.name
    end
    
    it "should create DynamicAdapter" do
      @sa1 = SourceAdapter.create(@s2)
      @sa1.class.name.should == 'Rhosync::DynamicAdapter'
    end
    
    it "should capture exception in create" do
      DynamicAdapter.should_receive(:new).once.and_raise(Exception)
      lambda { @sa1 = SourceAdapter.create(@s2) }.should raise_error(Exception)
    end

    it "should create SourceAdapter with trailing spaces" do
      @s.name = 'SimpleAdapter '
      SourceAdapter.create(@s).is_a?(SimpleAdapter).should be_true
    end

    describe "SourceAdapter methods" do
      it "should execute SourceAdapter login method with source vars" do
        @sa.login.should == true
      end

      it "should execute SourceAdapter query method" do
        expected = {'1'=>@product1,'2'=>@product2}
        @sa.inject_result expected
        @sa.query.should == expected
      end

      it "should execute SourceAdapter search method and modify params" do
        params = {:hello => 'world'}
        expected = {'1'=>@product1,'2'=>@product2}
        @sa.inject_result expected
        @sa.search(params).should == expected
        params.should == {:hello => 'world', :foo => 'bar'}
      end

      it "should execute SourceAdapter login with current_user" do
        @sa.should_receive(:current_user).with(no_args()).and_return(@u)
        @sa.login
      end

      it "should execute SourceAdapter sync method" do
        expected = {'1'=>@product1,'2'=>@product2}
        @sa.inject_result expected
        @sa.do_query
        Store.get_data(@s.docname(:md)).should == expected
        Store.get_value(@s.docname(:md_size)).to_i.should == 2
      end

      it "should fail gracefully if @result is missing" do
        @sa.inject_result nil
        lambda { @sa.query }.should_not raise_error
      end

      it "should reset count if @result is empty" do
        @sa.inject_result({'1'=>@product1,'2'=>@product2})
        @sa.do_query
        Store.get_value(@s.docname(:md_size)).to_i.should == 2
        @sa.inject_result({})
        @sa.do_query
        Store.get_value(@s.docname(:md_size)).to_i.should == 0
      end

      it "should execute SourceAdapter create method" do
        @sa.create(@product4).should == 'obj4'
      end

      it "should stash @result in store and set it to nil" do
        expected = {'1'=>@product1,'2'=>@product2}
        @sa.inject_result(expected)
        @sa.inject_tmpdoc('tmpdoc')
        @sa.stash_result
        Store.get_data('tmpdoc').should == expected
      end

      describe "SourceAdapter metadata method" do

        it "should execute SourceAdapter metadata method" do
          mock_metadata_method([SimpleAdapter]) do
            @sa.metadata.should == "{\"foo\":\"bar\"}"
          end
        end
      end
    end
  end
end