require 'log4r'
$:.unshift File.join(File.dirname(__FILE__),'..')
$:.unshift File.join(File.dirname(__FILE__),'..','lib')
require 'trunner/logging'
require 'trunner/mock_client'
require 'trunner/utils'
require 'trunner/result'
include Trunner

describe "TrunnerSpecHelper", :shared => true do
  before(:each) do
    Store.create
    Store.db.flushdb
    
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

  def set_state(state)
    state.each do |dockey,data|
      if data.is_a?(Hash) or data.is_a?(Array)
        Store.put_data(dockey,data)
      else
        Store.put_value(dockey,data)
      end
    end
  end
  
  def verify_result(result)
    result.each do |dockey,expected|
      if expected.is_a?(Hash)
        Store.get_data(dockey).should == expected
      elsif expected.is_a?(Array)
        Store.get_data(dockey,Array).should == expected
      else
        Store.get_value(dockey).should == expected
      end
    end
  end
  
end
