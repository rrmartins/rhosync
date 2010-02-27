class Trunnerapp
  class << self
    def authenticate(username,password,session)
      session[:auth] = "delegated"
      password == 'wrongpass' ? false : true
    end
  end
end