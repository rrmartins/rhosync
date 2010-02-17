Rhosync
-------------------------------------------------------------

Redis-powered rhosync with built-in sinatra application.

INSTALL
-------------------------------------------------------------
1. Make sure you have the following gems installed:

	* gem install rspec json sqlite3-ruby faker redis redis-namespace sinatra rack-test rubyzip uuidtools resque
	* gem uninstall rcov
	* gem install relevance-rcov
	
2. Install and start a redis server (see <http://code.google.com/p/redis/wiki/QuickStart>)

3. Install hsqldata.jar to vendor/ directory.  See <http://github.com/rhomobile/hsqldata> for instructions on how to build hsqldata.

4. "rake" to run all spec tasks, "rake doc" to see client/server protocol documentation
Windows Notes: when run any spec task error message box (ruby.exe - Unable to locate component) will appear. Just press 'OK'. 
This is problem with relevance-rcov.

5. Checkout the API documentation: <http://rdoc.info/projects/rhomobile/rhosync-datacache>

DOCS
-------------------------------------------------------------
Run 'rake doc' to generate documentation files.  See the result in doc/protocol.html.