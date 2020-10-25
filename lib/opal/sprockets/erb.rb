require 'tilt'
require 'sprockets'
require 'opal/sprockets/processor'

class Opal::Sprockets::ERBProcessor < ::Opal::Sprockets::Processor
  def initialize_engine
    super
    require_template_library 'opal/erb'
  end

  def evaluate(context, locals, &block)
    compiler = Opal::ERB::Compiler.new(@data, context.logical_path.sub(/#{Opal::REGEXP_START}templates\//, ''))
    @data = compiler.prepared_source
    super
  end

  # @deprecated
  ::Opal::ERB::Processor = self
end

Tilt.register 'opalerb', Opal::Sprockets::ERBProcessor
Sprockets.register_engine '.opalerb', Opal::Sprockets::ERBProcessor, mime_type: 'application/javascript', silence_deprecation: true
