warn "Opal::Processor is deprecated, please switch to Opal::Sprockets::Processor.", uplevel: 1

require 'opal/sprockets/processor'
Opal::Processor = Opal::Sprockets::Processor
