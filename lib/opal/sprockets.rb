require 'opal'
require 'opal/sprockets/version'

module Opal
  module Sprockets
    autoload :AssetsHelper, 'opal/sprockets/assets_helper'
    autoload :Environment, 'opal/sprockets/environment'
    autoload :ERB, 'opal/sprockets/erb'
    autoload :MimeTypes, 'opal/sprockets/mime_types'
    autoload :Processor, 'opal/sprockets/processor'
    autoload :Server, 'opal/sprockets/server'

    extend AssetsHelper
    extend MimeTypes
  end
end
