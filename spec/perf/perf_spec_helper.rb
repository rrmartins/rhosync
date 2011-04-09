require File.join(File.dirname(__FILE__),'..','spec_helper')
require 'faker'

shared_examples_for "PerfSpecHelper" do
  include TestHelpers    
  
  let(:test_app_name) { 'application' }
  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end
  before(:each) do 
    Store.create
    Store.db.flushdb
  end
  before(:each) do
    @a_fields = { :name => test_app_name }
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
  
  def get_test_data(num=1000)
    file = File.join("spec","testdata","#{num}-data.txt")
    data = nil
    if File.exists?(file)
      data = open(file, 'r') {|f| Marshal.load(f)}
    else
      data = generate_fake_data(num)
      f = File.new(file, 'w')
      f.write Marshal.dump(data)
      f.close
    end
    data
  end
  
  private

  PREFIX = ["Account", "Administrative", "Advertising", "Assistant", "Banking", "Business Systems", 
    "Computer", "Distribution", "IT", "Electronics", "Environmental", "Financial", "General", "Head", 
    "Laboratory", "Maintenance", "Medical", "Production", "Quality Assurance", "Software", "Technical", 
    "Chief", "Senior"] unless defined? PREFIX
  SUFFIX = ["Clerk", "Analyst", "Manager", "Supervisor", "Plant Manager", "Mechanic", "Technician", "Engineer", 
    "Director", "Superintendent", "Specialist", "Technologist", "Estimator", "Scientist", "Foreman", "Nurse", 
    "Worker", "Helper", "Intern", "Sales", "Mechanic", "Planner", "Recruiter", "Officer", "Superintendent",
    "Vice President", "Buyer", "Production Supervisor", "Chef", "Accountant", "Executive"] unless defined? SUFFIX
  
  def title
    prefix = PREFIX[rand(PREFIX.length)]
    suffix = SUFFIX[rand(SUFFIX.length)]

    "#{prefix} #{suffix}"
  end

  def generate_fake_data(num=1000)
    res = {}
    num.times do |n|
      res[n.to_s] = {
        "FirstName" => Faker::Name.first_name,
        "LastName" => Faker::Name.last_name,
        "Email" =>  Faker::Internet.free_email,
        "Company" => Faker::Company.name,
        "JobTitle" => title,
        "Phone1" => Faker::PhoneNumber.phone_number
      }
    end
    res
  end
end