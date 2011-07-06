require "cgi"

class XDomainSessionWrapper
  def initialize(app, opts={})
    @app = app
    @session_cookie = opts[:session_cookie] || 'rhosync_session'
    @api_uri_regexp = opts[:api_uri_regexp] || /\A\/api\/application/
    @login_uri_regexp = opts[:login_uri_regexp] || /\A\/api\/application\/clientlogin/
    yield self if block_given?
  end

  def is_sync_protocol(env)
    # if it is rhosync protocol URI
    @api_uri_regexp.match(env['PATH_INFO'])
  end

  def call(env)
    if is_sync_protocol(env)
      env['HTTP_COOKIE'] = env['HTTP_COOKIE'] || CGI.unescape(get_session_from_url(env))
    end

    response = @app.call(env)

    if is_sync_protocol(env)
      cookies = response[1]['Set-Cookie'].to_s
      #puts "<----- Cookies: #{cookies}"
      # put cookies to body as JSON on login success
      if @login_uri_regexp.match(env['PATH_INFO']) && response[0] == 200
        body = session_json_from(cookies)
        response[1]['Content-Length'] = body.length.to_s
        # TODO: This is temporary workaround since ruby 1.9 strings don't respond_to? :each
        response[2] = RUBY_VERSION.match(/1.8/) ? body : [body]
      end
    end

    puts "response: #{response.inspect}"
    response
  end

  def session_json_from(cookies)
    rexp = Regexp.new(@session_cookie +'=[^\s]*')
    sc = cookies.to_s.slice rexp
    "{\"" +@session_cookie +"\": \"#{CGI.escape sc.to_s}\"}"
  end

  def get_session_from_url(env)
    rexp = Regexp.new(@session_cookie +'=.*\Z')
    qs = env['QUERY_STRING'].to_s.slice rexp
    qs = qs.to_s.split(/&/)[0]
    nv = qs.to_s.split(/=/)
    return nv[1] if nv.length > 1
    ''
  end
end
