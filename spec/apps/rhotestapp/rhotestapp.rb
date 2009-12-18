class Rhotestapp
  class << self
    def authenticate(username,password,session)
      session[:auth] = "delegated"
      true
    end
  end
end