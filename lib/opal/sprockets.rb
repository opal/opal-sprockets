require 'opal'
require 'opal/sprockets/processor'
require 'opal/sprockets/erb'
require 'opal/sprockets/server'

module Opal
  module Sprockets
    # Bootstraps modules loaded by sprockets on `Opal.modules` marking any
    # non-Opal asset as already loaded.
    #
    # @example
    #
    #   Opal::Sprockets.load_asset('application')
    #
    # @example Will output the following JavaScript:
    #
    #   Opal.loaded("jquery.self", "yet_another_carousel.self");
    #   Opal.require("opal", "application");
    #
    # @param name [String] The logical name of the main asset to be loaded (without extension)
    #
    # @return [String] JavaScript code
    def self.load_asset(*names)
      if names.last.is_a?(::Sprockets::Environment)
        unless @load_asset_warning_displayed
          @load_asset_warning_displayed = true
          warn "Passing a sprockets environment to Opal::Sprockets.load_asset no more needed.\n  #{caller(1, 3).join("\n  ")}"
        end
        names.pop
      end

      names = names.map { |name| name.sub(/(\.(js|rb|opal))*\z/, '') }
      stubbed = ::Opal::Config.stubbed_files.to_a

      loaded = 'typeof(OpalLoaded) === "undefined" ? [] : OpalLoaded'
      loaded = "#{stubbed.to_json}.concat(#{loaded})" if stubbed.any?

      [
        "Opal.loaded(#{loaded});",
        *names.map { |name| "Opal.require(#{name.to_json});" }
      ].join("\n")
    end

    # Mark an asset as already loaded.
    # This is useful for requiring JavaScript files which are not managed by Opal's laoding system.
    #
    # @param [String] name The "logical name" of the asset
    # @return [String] JavaScript code
    def self.loaded_asset(name)
      %{if (typeof(OpalLoaded) === 'undefined') OpalLoaded = []; OpalLoaded.push(#{name.to_json});}
    end

    # Generate a `<script>` tag for Opal assets.
    #
    # @param [String] name     The logical name of the asset to be loaded (without extension)
    # @param [Hash]   options  The options about sprockets
    # @option options [Sprockets::Environment] :sprockets  The sprockets instance
    # @option options [String]                 :prefix     The prefix String at which is mounted Sprockets, e.g. '/assets'
    # @option options [Boolean]                :debug      Wether to enable debug mode along with sourcemaps support
    #
    # @return a string of HTML code containing `<script>` tags.
    def self.javascript_include_tag(name, options = {})
      sprockets = options.fetch(:sprockets)
      prefix    = options.fetch(:prefix)
      debug     = options.fetch(:debug)

      # Avoid double slashes
      prefix = prefix.chop if prefix.end_with? '/'

      asset = sprockets[name]
      raise "Cannot find asset: #{name}" if asset.nil?
      scripts = []

      if debug
        asset.to_a.map do |dependency|
          scripts << %{<script src="#{prefix}/#{dependency.digest_path}?body=1"></script>}
        end
      else
        scripts << %{<script src="#{prefix}/#{name}.js"></script>}
      end

      scripts << %{<script>#{load_asset('opal', name)}</script>}

      scripts.join "\n"
    end
  end
end
