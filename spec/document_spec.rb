require File.join(File.dirname(__FILE__),'spec_helper')

describe "Document" do
  before(:each) do
    @doctype = 'md'
    @source = 'TestSource'
    @user = 5
    @client = 12345
    @app = 2
    @d = Document.new(@doctype,@app,@user,@client,@source)
  end
  
  it "should get_key" do
    @d.get_key.should == "#{@doctype}:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_delete_page_dockey" do
    @d.get_delete_page_dockey.should == "#{@doctype}-delete-page:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_page_dockey" do
    @d.get_page_dockey.should == "#{@doctype}-page:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_page_token_dockey" do
    @d.get_page_token_dockey.should == "#{@doctype}-page-token:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_search_dockey" do
    @d.get_search_dockey.should == "#{@doctype}-search:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_search_errors_dockey" do
    @d.get_search_errors_dockey.should == "#{@doctype}-search-errors:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_update_dockey" do
    @d.get_update_dockey.should == "#{@doctype}-update:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_delete_dockey" do
    @d.get_delete_dockey.should == "#{@doctype}-delete:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_delete_errors_dockey" do
    @d.get_delete_errors_dockey.should == "#{@doctype}-delete-errors:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_create_dockey" do
    @d.get_create_dockey.should == "#{@doctype}-create:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_source_errors_dockey" do
    @d.get_source_errors_dockey.should == "#{@doctype}-source-errors:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_create_errors_dockey" do
    @d.get_create_errors_dockey.should == "#{@doctype}-create-errors:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_create_links_dockey" do
    @d.get_create_links_dockey.should == "#{@doctype}-create-links:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"    
  end
  
  it "should get_datasize_dockey" do
    @d.get_datasize_dockey.should == "#{@doctype}-datasize:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"    
  end
end