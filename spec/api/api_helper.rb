require File.join(File.dirname(__FILE__),'..','spec_helper')
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'

require File.join(File.dirname(__FILE__),'..','..','lib','rhosync','server.rb')

describe "ApiHelper", :shared => true do
  it_should_behave_like "RhosyncDataHelper"

  include Rack::Test::Methods
  include Rhosync
  
  before(:each) do
    require File.join(get_testapp_path,@test_app_name)
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(rhosync.base_directory,'..','..','..','vendor')
    end
    Server.set( 
      :environment => :test,
      :run => false,
      :secret => "secure!"
    )
    @api_token = User.load('rhoadmin').token_id
  end

  def app
    @app ||= Server.new
  end

  it_should_behave_like "DBObjectsHelper"
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
