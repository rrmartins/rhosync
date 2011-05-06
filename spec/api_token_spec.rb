require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "ApiToken" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    it "should generate api token with user" do
      token = ApiToken.create(:user_id => @u.id)
      token.value.length.should == 32
      token.user_id.should == @u.id
      token.user.login.should == @u.login
      token.delete
    end
  end
end
