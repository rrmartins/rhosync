require 'digest/sha1'

module RhosyncStore
  # Inspired by sinatra-authentication
  # Password uses simple sha1 digest for hashing
  class User < Model
    field :login,:string
    field :email,:string
    field :salt,:string
    field :hashed_password,:string
    set   :clients, :string
    field :admin, :int
    field :token_id, :string
    
    class << self
      def create(fields={})
        fields[:id] = fields[:login]
        super(fields)
      end
    
      def authenticate(login,password)
        return unless is_exist?(login,'login')
        current_user = with_key(login)
        return if current_user.nil?
        return current_user if User.encrypt(password, current_user.salt) == current_user.hashed_password
      end
    end
    
    def password=(pass)
      @password = pass
      self.salt = User.random_string(10) if !self.salt
      self.hashed_password = User.encrypt(@password, self.salt)
    end
    
    def delete
      clients.members.each do |client_id|
        Client.with_key(client_id).delete
      end
      super
    end
    
    def create_token
      if self.token_id && ApiToken.is_exist?(self.token_id,'value')
        ApiToken.with_key(self.token_id).delete 
      end
      self.token_id = ApiToken.create(:user_id => self.login).id
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