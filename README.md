Rhosync
-------------------------------------------------------------

Redis-powered rhosync with built-in sinatra application.

INSTALL
-------------------------------------------------------------
1. Make sure you have the following gems installed:

	* rspec rcov json sqlite3-ruby faker redis redis-namespace sinatra rack-test rubyzip uuidtools resque
	
2. Install and start a redis server (v1.2 or greater is required) (see <http://code.google.com/p/redis/>)

3. Install hsqldata.jar to vendor/ directory.  See <http://github.com/rhomobile/hsqldata> for instructions on how to build hsqldata.

4. "rake" to run all specs

Windows Notes: when run any spec task error message box (ruby.exe - Unable to locate component) will appear. Just press 'OK'. This is problem with rcov.

5. Checkout the API documentation: <http://rdoc.info/projects/rhomobile/rhosync>

DOCS
-------------------------------------------------------------
Run 'rake doc' to generate documentation files.  See the result in doc/protocol.html.