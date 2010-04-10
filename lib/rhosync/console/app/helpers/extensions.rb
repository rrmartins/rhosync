class Hash
public
    def symbolize_keys
      hash = {}
      self.each do |key, value|
        hash[(key.to_sym rescue key) || key] = value
      end
      hash
    end
end

class String
public
  def ends_with?(str)
    str = str.to_str
    tail = self[-str.length, str.length]
    tail == str      
  end
end  