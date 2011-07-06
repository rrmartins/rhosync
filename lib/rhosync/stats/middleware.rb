module Rhosync
  module Stats
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        start = Time.now.to_f
        response = @app.call(env)
        finish = Time.now.to_f
        metric = "http:#{env['REQUEST_METHOD']}:#{env['PATH_INFO']}"
        source_name = env['rack.request.query_hash']["source_name"] if env['rack.request.query_hash']
        metric << ":#{source_name}" if source_name
        Record.save_average(metric,finish - start)
        response
      end
    end
  end
end