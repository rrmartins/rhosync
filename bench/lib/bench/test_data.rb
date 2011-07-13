require 'ffaker'
require 'uuidtools'

module Bench
  module TestData
    def get_test_data(num=1000, generate=false, generate_blob=false)
      file_name = generate_blob ? "#{num}-blob_data.txt" : "#{num}-data.txt" 
      file = File.join(File.dirname(__FILE__), '..', "testdata", file_name)
      data = nil
      if File.exists?(file) and not generate
        data = open(file, 'r') {|f| Marshal.load(f)}
      else
        data = generate_fake_data(num, generate_blob)
        f = File.new(file, 'w')
        f.write Marshal.dump(data)
        f.close
      end
      data
    end

    def get_image_data(objs)
      blobs = {}
      objs.keys.each do |key|
        img_file_name = objs["#{key}"]["filename"] 
        blobs["img_file-rhoblob-#{key}"] = 
          File.new(File.join(File.dirname(__FILE__), "..", "testdata", "images", "#{img_file_name}"), 'rb')
      end
      blobs
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

    IMAGE_FILES = %w{  
      icon.ico                loading-LandscapeLeft.png   loading-PortraitUpsideDown.png
      icon.png                loading-LandscapeRight.png  loading.png
      loading-Landscape.png   loading-Portrait.png        loading@2x.png }
    
    EXCLUDE_LIST = %w{ id  mock_id  img_file-rhoblob  filename }
      
    def title
      prefix = PREFIX[rand(PREFIX.length)]
      suffix = SUFFIX[rand(SUFFIX.length)]

      "#{prefix} #{suffix}"
    end

    def generate_fake_data(num, generate_blob)
      res = {}
      num.times do |n|
        mock_id = UUIDTools::UUID.random_create.to_s.gsub(/\-/,'')
        res[mock_id] = {
          "mock_id" => mock_id,
          "FirstName" => Faker::Name.first_name,
          "LastName" => Faker::Name.last_name,
          "Email" =>  Faker::Internet.free_email,
          "Company" => Faker::Company.name,
          "JobTitle" => title,
          "Phone1" => Faker::PhoneNumber.phone_number
        }
        if generate_blob
          img_file_name = IMAGE_FILES[rand(IMAGE_FILES.size)]
          res[mock_id]["img_file-rhoblob"] = img_file_name
          res[mock_id]["filename"] = img_file_name
          
          # Additional fields: from 0 to 51 fields will be added to existing 9 ones (total upto 60)
          words = Faker::Lorem.words(rand(51))
          words.each do |word|
            res[mock_id]["#{word}"] = word unless EXCLUDE_LIST.include?(word)
          end  
        end
      end
      res
    end
  end
end