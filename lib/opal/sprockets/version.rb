module Opal
  module Sprockets
    BASE_VERSION = '0.5.0'
    OPAL_VERSION = '1.0.0'
    SPROCKETS_VERSION = '4.0'

    # Just keep the first two segments of dependencies' versions
    v = -> v { v.split('.')[0..1].compact.join('.') }

    VERSION = "#{BASE_VERSION}.#{v[OPAL_VERSION]}.#{v[SPROCKETS_VERSION]}"
  end
end
