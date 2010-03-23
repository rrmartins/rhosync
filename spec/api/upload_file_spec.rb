require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiUploadFile" do
  it_should_behave_like "ApiHelper"
  
  it "should upload and unzip file" do
    file = File.join(File.dirname(__FILE__),'..','testdata','compressed')    
    compress(file)
    zipfile = File.join(file,"compressed.zip")
    post "/api/upload_file", :app_name => @appname, :api_token => @api_token,
      :upload_file => Rack::Test::UploadedFile.new(zipfile, "application/octet-stream")
    FileUtils.rm zipfile
    expected = File.join(Rhosync.app_directory,'compress-data.txt')
    File.exists?(expected).should == true
    File.read(expected).should == 'some compressed text'
    FileUtils.rm expected
  end
  
  it "should fail to upload a non-zip file" do
    file = File.join(File.dirname(__FILE__),'..','testdata','compressed','compress-data.txt')    
    post "/api/upload_file", :app_name => @appname, :api_token => @api_token,
      :upload_file => Rack::Test::UploadedFile.new(file, "application/octet-stream")
    last_response.status.should == 500
    File.exists?(File.join(Rhosync.app_directory,'compress-data.txt')).should == false
  end
end