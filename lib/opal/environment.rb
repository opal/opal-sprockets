warn "Opal::Environment is deprecated, please switch to Opal::Sprockets::Environment.", uplevel: 1

require 'opal/sprockets/environment'
Opal::Environment = Opal::Sprockets::Environment
