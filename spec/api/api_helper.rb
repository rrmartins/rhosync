require File.join(File.dirname(__FILE__),'..','spec_helper')
require 'rack/test'
require 'rspec'

require File.join(File.dirname(__FILE__),'..','..','lib','rhosync','server.rb')

shared_examples_for "ApiHelper" do
  include Rack::Test::Methods
  include Rhosync
  include TestHelpers    

  # it_should_behave_like "RhosyncDataHelper"
  let(:test_app_name) { 'application' }
  before(:each) do
    Store.create
    Store.db.flushdb
  end
  
  before(:each) do
    require File.join(get_testapp_path, test_app_name)
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(rhosync.base_directory,'..','..','..','vendor')
    end
    Rhosync::Server.set( 
      :environment => :test,
      :run => false,
      :secret => "secure!"
    )
    @api_token = User.load('rhoadmin').token_id
  end

  def app
    @app ||= Rhosync::Server.new
  end

  # it_should_behave_like "DBObjectsHelper"
  before(:each) do
    @a_fields = { :name => test_app_name }
    # @a = App.create(@a_fields)
    @a = (App.load(test_app_name) || App.create(@a_fields))
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'Apple',
      :device_pin => 'abcd',
      :device_port => '3333',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.load(@s_fields[:name],@s_params)
    @s = Source.create(@s_fields,@s_params) if @s.nil?
    @s1 = Source.load('FixedSchemaAdapter',@s_params)
    @s1 = Source.create({:name => 'FixedSchemaAdapter'},@s_params) if @s1.nil?
    config = Rhosync.source_config["sources"]['FixedSchemaAdapter']
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources.members)
    @a.users << @u.id
  end
  before(:each) do
    @source = 'Product'
    @user_id = 5
    @client_id = 1

    @product1 = {
      'name' => 'iPhone',
      'brand' => 'Apple',
      'price' => '199.99'
    }

    @product2 = {
      'name' => 'G2',
      'brand' => 'Android',
      'price' => '99.99'
    }

    @product3 = {
      'name' => 'Fuze',
      'brand' => 'HTC',
      'price' => '299.99'
    }

    @product4 = {
      'name' => 'Droid',
      'brand' => 'Android',
      'price' => '249.99'
    }

    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end

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
