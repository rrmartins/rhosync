module Bench
  class Session
    include Logging
    include Timer
    attr_accessor :cookies, :last_result, :results, :thread_id, :iteration, :client_id
    
    def initialize(thread_id,iteration)
      @cookies = {}
      @results = {}
      @thread_id,@iteration = thread_id,iteration
    end
      
    def post(marker,url,headers={})
      @body = yield
      _request(marker,:_post,url,headers)
    end
    
    def get(marker,url,headers={})
      params = yield if block_given?
      url_params = url.clone
      url_params << "?" + _url_params(params) if params
      _request(marker,:_get,url_params,headers)          
    end
    
    protected
    def _request(marker,verb,url,headers)
      result = Result.new(marker,verb,url,@thread_id,@iteration)
      @results[result.marker] ||= []
      @results[result.marker] << result
      begin
        result.time = time do
          headers.merge!(:cookies => @cookies)
            result.last_response = send(verb,url,headers)
            @last_result = result  
        end
        logger.info "#{log_prefix} #{verb.to_s.upcase.gsub(/_/,'')} #{url} #{@last_result.code} #{result.time}"      
      rescue RestClient::Exception => e
        result.error = e
        logger.info "#{log_prefix} #{verb.to_s.upcase.gsub(/_/,'')} #{url}"      
        logger.error "#{log_prefix} #{e.http_code.to_s} #{e.message}\n"
        raise e
      end
      @cookies = @cookies.merge(@last_result.cookies)
      @last_result
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