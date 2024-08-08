require 'set'
require 'base64'
require 'tilt/opal'
require 'sprockets'
require 'opal/builder'
require 'opal/sprockets'

# Internal: The Processor class is used to make ruby files (with .rb or .opal
#   extensions) available to any sprockets based server. Processor will then
#   get passed any ruby source file to build.
class Opal::Sprockets::Processor
  @@cache_key = nil
  def self.cache_key
    gem_config = Gem.loaded_specs.map {|gem_key, gem_spec| [gem_spec.name, gem_spec.version.to_s] }
    @@cache_key ||= ['Opal', Opal::VERSION, Opal::Config.config, gem_config].to_json.freeze
  end

  def self.reset_cache_key!
    @@cache_key = nil
  end

  def self.call(input)
    data, map, dependencies, required = input[:cache].fetch([self.cache_key, input[:filename], input[:data]]) do
      new(input).call
    end

    if map
      map = ::Sprockets::SourceMapUtils.combine_source_maps(input[:metadata][:map], map)
    end

    {
      data: data,
      map: map,
      dependencies: input[:metadata][:dependencies].to_a + dependencies.to_a,
      required: input[:metadata][:required].to_a + required.to_a,
    }
  end

  def initialize(input)
    @input = input
    @sprockets = input[:environment]
    @context = sprockets.context_class.new(input)
    @data = input[:data]
  end

  attr_reader :input, :sprockets, :context, :data

  # In Sprockets 3 logical_path has an odd behavior when the filename is "index"
  # thus we need to bake our own logical_path
  def logical_path
    @logical_path ||= context.filename.gsub(%r{^#{Regexp.escape(context.root_path)}/?(.*?)}, '\1')
  end

  def call
    compiler_options = Opal::Config.compiler_options.merge(requirable: true, file: logical_path)

    compiler = Opal::Compiler.new(data, compiler_options)
    result = compiler.compile

    process_requires(compiler.requires, context)
    process_required_trees(compiler.required_trees, context)

    if Opal::Config.source_map_enabled
      map = compiler.source_map.as_json.transform_keys!(&:to_s)
      map["sources"][0] = input[:filename]
      map = ::Sprockets::SourceMapUtils.format_source_map(map, input)
    end

    [result.to_s, map , context.metadata[:dependencies], context.metadata[:required]]
  end

  def sprockets_extnames_regexp
    @sprockets_extnames_regexp ||= Opal::Sprockets.sprockets_extnames_regexp(@sprockets)
  end

  def process_requires(requires, context)
    requires.each do |required|
      required = required.to_s.sub(sprockets_extnames_regexp, '')
      context.require_asset required unless ::Opal::Config.stubbed_files.include? required
    end
  end

  # Internal: Add files required with `require_tree` as asset dependencies.
  #
  # Mimics (v2) Sprockets::DirectiveProcessor#process_require_tree_directive
  def process_required_trees(required_trees, context)
    return if required_trees.empty?

    # This is the root dir of the logical path, we need this because
    # the compiler gives us the path relative to the file's logical path.
    dirname = File.dirname(input[:filename]).gsub(/#{Regexp.escape File.dirname(context.logical_path)}#{Opal::REGEXP_END}/, '')
    dirname = Pathname(dirname)

    required_trees.each do |original_required_tree|
      required_tree = Pathname(original_required_tree)

      unless required_tree.relative?
        raise ArgumentError, "require_tree argument must be a relative path: #{required_tree.inspect}"
      end

      required_tree = dirname.join(input[:filename], '..', required_tree)

      unless required_tree.directory?
        raise ArgumentError, "require_tree argument must be a directory: #{{source: original_required_tree, pathname: required_tree}.inspect}"
      end

      context.depend_on required_tree.to_s

      environment = context.environment

      processor = ::Sprockets::DirectiveProcessor.new
      processor.instance_variable_set('@dirname', File.dirname(input[:filename]))
      processor.instance_variable_set('@environment', environment)
      path = processor.__send__(:expand_relative_dirname, :require_tree, original_required_tree)
      absolute_paths = environment.__send__(:stat_sorted_tree_with_dependencies, path).first.map(&:first)

      absolute_paths.each do |path|
        path = Pathname(path)
        pathname = path.relative_path_from(dirname).to_s
        pathname_noext = pathname.sub(sprockets_extnames_regexp, '')

        if path.to_s == logical_path then next
        elsif ::Opal::Config.stubbed_files.include?(pathname_noext) then next
        elsif path.directory? then context.depend_on(path.to_s)
        else context.require_asset(pathname_noext)
        end
      end
    end
  end

  private

  def to_data_uri_comment(map_to_json)
    "//# sourceMappingURL=data:application/json;base64,#{Base64.encode64(map_to_json).delete("\n")}"
  end

  def stubbed_files
    ::Opal::Config.stubbed_files
  end

  module PlainJavaScriptLoader
    def self.call(input)
      sprockets = input[:environment]

      opal_extnames_regexp = Opal::Sprockets.sprockets_extnames_regexp(sprockets, opal_only: true)

      if input[:filename] =~ opal_extnames_regexp
        input[:data]
      else
        "#{input[:data]};#{Opal::Sprockets.loaded_asset(input[:name])}"
      end
    end
  end
end

Sprockets.register_mime_type 'application/ruby', extensions: ['.rb', '.opal', '.js.rb', '.js.opal']
Sprockets.register_transformer 'application/ruby', 'application/javascript', Opal::Sprockets::Processor
Opal::Sprockets.register_mime_type 'application/ruby'

Sprockets.register_mime_type 'application/ruby+ruby', extensions: ['.rb.erb', '.opal.erb', '.js.rb.erb', '.js.opal.erb']
Sprockets.register_transformer 'application/ruby+ruby', 'application/ruby', Sprockets::ERBProcessor
Opal::Sprockets.register_mime_type 'application/ruby+ruby'

Sprockets.register_preprocessor 'application/ruby', Sprockets::DirectiveProcessor.new(comments: ["#"])
Sprockets.register_preprocessor 'application/ruby+ruby', Sprockets::DirectiveProcessor.new(comments: ["#"])

Sprockets.register_postprocessor 'application/javascript', Opal::Sprockets::Processor::PlainJavaScriptLoader
