require 'tilt'
require 'sprockets'
require 'opal/sprockets'
require 'opal/sprockets/processor'

module Opal
  module ERB
    class Processor < ::Opal::Processor
      def initialize_engine
        super
        require_template_library 'opal/erb'
      end

      def evaluate(context, locals, &block)
        compiler = Opal::ERB::Compiler.new(@data, context.logical_path.sub(/#{REGEXP_START}templates\//, ''))
        @data = compiler.prepared_source
        super
      end
    end
  end
end

# We can use a plain .erb extension now, woo!
Sprockets.register_mime_type 'application/html+ruby', extensions: ['.opalerb', '.erb', '.html.erb']
Sprockets.register_transformer 'application/html+ruby', 'application/javascript', Opal::ERB::Processor
Opal::Sprockets.register_mime_type 'application/html+ruby'

Tilt.register 'opalerb', Opal::ERB::Processor
