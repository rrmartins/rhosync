module Trunner
  class Session
    include Logging
    include Timer
    attr_accessor :cookies, :last_response, :test_var
    
    def initialize(tv)
      @cookies = {}
      @response_times = []
    end
    
    def test
      yield self
    end
      
    def post(url,headers={})
      @body = yield
      _request(:_post,url,headers)
    end
    
    def get(url,headers={})
      params = yield if block_given?
      url << "?" + _url_params(params) if params
      _request(:_get,url,headers)          
    end
    
    def verify(expected,actual)
      expected,actual = JSON.parse(expected),JSON.parse(actual)
      if expected != actual
        puts "Verify error at: " + caller(1)[0].to_s
        puts "expected:\n#{expected.inspect}\n but got:\n#{actual.inspect}" 
      end
    end
    
    protected
    def _request(verb,url,headers)
      @response_times << time do
        headers.merge!(:cookies => @cookies)
        begin
          @last_response = send(verb,url,headers)  
        rescue RestClient::Exception => e
          logger.error "#{e.http_code.to_s} #{e.message}\n"
        end
      end
      logger.info "#{verb.to_s.upcase.gsub(/_/,'')} #{url} #{@last_response.code} #{@response_times.last}"      
      @cookies = @cookies.merge(@last_response.cookies)
      @last_response
    end
    
    def _get(url,headers)
      #logger.info "GET #{url}"
      RestClient.get(url, headers)
    end
    
    def _post(url,headers)
      #logger.info "POST #{url}"
      RestClient.post(url, @body, headers)
    end
    
    def _url_params(params)
      elements = []
      params.each do |key,value|
        elements << "#{key}=#{value}"
      end
      elements.join('&')
    end
  end
end