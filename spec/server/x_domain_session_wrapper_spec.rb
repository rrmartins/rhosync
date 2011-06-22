require 'rhosync/x_domain_session_wrapper'
require File.join(File.dirname(__FILE__),'..','spec_helper')

require "cgi"

COOKIE_NAME = 'some_cookie'
COOKIE_VALUE = 'some_session_key=some_session_value'

COOKIE_NV = "#{COOKIE_NAME}=#{COOKIE_VALUE}"
COOKIE_ANOTHER_NV = "#{COOKIE_NAME}=#{COOKIE_VALUE}_another"

PROPER_QUERY_STRING = "?abc=123&#{COOKIE_NAME}=#{CGI.escape(COOKIE_VALUE)}&de=45"
WRONG_QUERY_STRING = "?abc=123&#{COOKIE_NAME}_wrong=#{CGI.escape(COOKIE_VALUE)}&de=45"

PROPER_URI = '/application'
WRONG_URI = '/some/wrong/path/to/rhosync/application'

LOGIN_URI = '/application/clientlogin'

describe "XDomainSessionWrapper middleware" do

  class StubApp
    def call(env)
      [200, {'Set-Cookie' => COOKIE_ANOTHER_NV, 'Content-Length' => '0'}, '']
    end
  end

  before(:each) do
    app ||= StubApp.new
    @middleware = XDomainSessionWrapper.new(app, {:session_cookie => COOKIE_NAME})
  end

  it "should skip if it isn't a sync protocol URI" do
    env = {
        'REQUEST_PATH' => WRONG_URI,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    COOKIE_NV.should_not == env['HTTP_COOKIE']
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
  end

  it "should process cookie from QUERY_STRING if it is a sync protocol URI" do
    env = {
        'REQUEST_PATH' => PROPER_URI,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    env['HTTP_COOKIE'].should == COOKIE_VALUE
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
  end

  it "shouldn't process cookie from QUERY_STRING if there is no appropriate parameter name or value" do
    env = {
        'REQUEST_PATH' => PROPER_URI,
        'QUERY_STRING' => WRONG_QUERY_STRING
    }
    status, headers, body = @middleware.call(env)
    200.should == status
    COOKIE_ANOTHER_NV.should == headers['Set-Cookie']
    env['HTTP_COOKIE'].should_not == COOKIE_VALUE
    headers['Content-Length'].should == body.length.to_s
    ''.should == body
  end

  it "should respond with cookie in a body if it is a login URI" do
    env = {
        'REQUEST_PATH' => LOGIN_URI,
        'QUERY_STRING' => PROPER_QUERY_STRING
    }
    status, headers, body = @middleware.call(env)
    200.should == status
    headers['Set-Cookie'].should == COOKIE_ANOTHER_NV
    env['HTTP_COOKIE'].should == COOKIE_VALUE
    headers['Content-Length'].should == body.length.to_s
    ''.should_not == body
  end
end
