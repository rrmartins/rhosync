require 'rack/test'
require 'rspec'

require File.join(File.dirname(__FILE__),'..','..','lib','rhosync','server.rb')
require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__), '..', 'support', 'shared_examples')

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
