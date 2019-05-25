module Opal
  module Sprockets
    BASE_VERSION = '0.4.5'
    OPAL_VERSION = '1.0.0'
    SPROCKETS_VERSION = '3.7'

    # Just keep the first two segments of dependencies' versions
    v = -> v { v.split('.')[0..1].compact.join('.') }

    VERSION = "#{BASE_VERSION}.#{v[OPAL_VERSION]}.#{v[SPROCKETS_VERSION]}"
  end
end
