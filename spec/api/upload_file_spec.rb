require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiUploadFile" do
  it_should_behave_like "ApiHelper"
  
  it "should upload and unzip file" do
    upload_test_apps
    file = File.join(File.dirname(__FILE__),'..','testdata')    
    compress(file)
    zipfile = File.join(file,"testdata.zip")
    post "/api/#{@appname}/upload_file", :api_token => @api_token, :payload => {
      :upload_file => Rack::Test::UploadedFile.new(zipfile, "application/octet-stream")}
    FileUtils.rm zipfile
    expected = File.join(App.appdir(@appname),'compress-data.txt')
    File.exists?(expected).should == true
    File.read(expected).should == 'some compressed text'
  end
end