module Opal
  module Sprockets
    # Note: I don't think it's used anymore.
    class PathReader
      def initialize(env, context)
        @env ||= env
        @context ||= context
      end

      def read path
        if path.end_with? '.js'
          context.depend_on_asset(path)
          env[path, accept: "application/javascript"].to_s
        else
          context.depend_on(path)
          File.open(expand(path), 'rb:UTF-8'){|f| f.read}
        end
      rescue ::Sprockets::FileNotFound
        nil
      end

      def expand path
        resolved_path = Array(env.resolve(path, accept: "application/javascript")).first
        if resolved_path
          URI.parse(resolved_path).path
        else
          # Sprockets 3 just returns nil for unknown paths
          raise ::Sprockets::FileNotFound, path.inspect
        end
      end

      def paths
        env.paths
      end

      attr_reader :env, :context
    end

  end
end
