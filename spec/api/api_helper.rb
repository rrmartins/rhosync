require File.join(File.dirname(__FILE__),'..','spec_helper')
$:.unshift File.join(__FILE__,'..','..','lib')
require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'
require 'rhosync'
include Rhosync

require File.join(File.dirname(__FILE__),'..','..','lib','rhosync','server.rb')

describe "ApiHelper", :shared => true do
  include Rack::Test::Methods
  
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @appname = @a_fields[:name]
    delete_app_directory
    basedir = File.join(File.dirname(__FILE__),'..','..')
    Rhosync.bootstrap do |rhosync|
      rhosync.base_directory = basedir
    end
    Server.set( 
      :environment => :test,
      :run => false,
      :secret => "secure!"
    )
    @api_token = User.load('admin').token_id
  end
  
  after(:each) do
    delete_app_directory
  end
  
  def delete_app_directory
    FileUtils.rm_rf File.join(File.dirname(__FILE__),'..','..','apps')
  end
  
  def app
    @app ||= Server.new
  end
end

def upload_test_apps
  file = File.join(File.dirname(__FILE__),'..','apps',@appname)
  compress(file)
  zipfile = File.join(file,"#{@appname}.zip")
  post "/api/import_app", :app_name => @appname, :api_token => @api_token, 
    :upload_file => Rack::Test::UploadedFile.new(zipfile, "application/octet-stream")
  FileUtils.rm_f zipfile
end

def compress(path)
  path.sub!(%r[/$],'')
  archive = File.join(path,File.basename(path))+'.zip'
  FileUtils.rm archive, :force=>true
  Zip::ZipFile.open(archive, 'w') do |zipfile|
    Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
      zipfile.add(file.sub(path+'/',''),file)
    end
  end
end
