require 'opal'
require 'opal/sprockets/version'

module Opal
  module Sprockets
    require 'opal/sprockets/assets_helper'
    require 'opal/sprockets/mime_types'
    extend AssetsHelper
    extend MimeTypes

    require 'opal/sprockets/environment'
    require 'opal/sprockets/erb'
    require 'opal/sprockets/processor'
    require 'opal/sprockets/server'
  end

  autoload :Processor, 'opal/processor'
  autoload :Environment, 'opal/environment'
end
