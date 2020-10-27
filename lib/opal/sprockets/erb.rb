require 'tilt'
require 'sprockets'
require 'opal/sprockets/processor'
require 'opal/erb'

class Opal::Sprockets::ERB < ::Opal::Sprockets::Processor
  def call
    compiler = Opal::ERB::Compiler.new(@data, logical_path.sub(/#{Opal::REGEXP_START}templates\//, ''))
    @data = compiler.prepared_source
    super
  end

  # @deprecated
  ::Opal::ERB::Processor = self
end

Sprockets.register_mime_type 'application/html+javascript+ruby', extensions: ['.opalerb', '.opal.erb', '.html.opal.erb']
Sprockets.register_transformer 'application/html+javascript+ruby', 'application/javascript', Opal::ERB::Processor
Opal::Sprockets.register_mime_type 'application/html+javascript+ruby'
