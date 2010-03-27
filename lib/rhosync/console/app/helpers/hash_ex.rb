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
