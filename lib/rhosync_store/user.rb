if RUBY_VERSION >= '1.9'
    require 'digest/sha1'
else
    require 'sha1'
end


module RhosyncStore
  # Inspired by sinatra-authentication
  # Password uses simple sha1 digest for hashing
  class User < Model
    field :login,:string
    field :email,:string
    field :salt,:string
    field :hashed_password,:string
    
    class << self
      def create(fields={})
        fields[:id] = fields[:login]
        super(fields)
      end
    
      def authenticate(login,password)
        return unless is_exist?(login)
        current_user = with_key(login)
        return if current_user.nil?
        return current_user if User.encrypt(password, current_user.salt) == current_user.hashed_password
      end
      
      def is_exist?(login)
        !redis.get(self._field_key(self._prefix,login,'login')).nil?
      end
    end
    
    def password=(pass)
      @password = pass
      self.salt = User.random_string(10) if !self.salt
      self.hashed_password = User.encrypt(@password, self.salt)
    end
    
    protected
    def self.encrypt(pass, salt)
      Digest::SHA1.hexdigest(pass+salt)
    end

    def self.random_string(len)
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      newpass = ""
      1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
      return newpass
    end
  end
end