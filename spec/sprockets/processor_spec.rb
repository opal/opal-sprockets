require 'spec_helper'
require 'opal/sprockets/processor'

describe Opal::Sprockets::Processor do
  let(:pathname) { Pathname("/Code/app/mylib/opal/foo.#{ext}") }
  let(:data) { "foo" }
  let(:input) { {
    environment: Opal::Sprockets::Environment.new.tap {|e| e.append_path "/Code/app/mylib/opal"},
    data: data,
    filename: pathname.to_s,
    load_path: "/Code/app/mylib/opal",
    metadata: {},
    cache: Sprockets::Cache.new
  } }

  before do
    allow(Sprockets::SourceMapUtils).to receive(:format_source_map)
    allow(Sprockets::SourceMapUtils).to receive(:combine_source_maps)
  end

  %w[.rb .opal].each do |ext|
    describe %{with extension "#{ext}"} do
      let(:ext) { ext }

      it "is registered for '#{ext}' files" do
        mime_type = Sprockets.mime_types.find { |_,v| v[:extensions].include? ".rb" }.first
        transformers = Sprockets.transformers[mime_type]
        transformer = transformers["application/javascript"]
        expect(transformer.processors).to include(described_class)
      end

      it "compiles the code" do
        result = described_class.call(input.merge data: "puts 'Hello, World!'\n")

        expect(result[:data]).to include('"Hello, World!"')
      end

      describe '.stubbed_files' do
        it 'requires non-stubbed files' do
          result = described_class.call(input.merge(data: 'require "set"'))

          expect(result[:required].first).to include("stdlib/set.rb")
        end

        it 'skips require of stubbed file' do
          Opal::Config.stubbed_files << 'set'
          result = described_class.call(input.merge(data: "require 'set'"))

          expect(result[:required]).not_to include("set.rb")
        end

        it 'marks a stubbed file as loaded' do
          Opal::Config.stubbed_files << 'set'
          result = described_class.call(input.merge(data: "require 'set'"))

          expect(result[:data]).not_to include(::Opal::Sprockets.load_asset('set'))
        end
      end

      describe '.cache_key' do
        it 'can be reset' do
          old_cache_key = described_class.cache_key
          Opal::Config.arity_check_enabled = !Opal::Config.arity_check_enabled
          stale_cache_key = described_class.cache_key

          described_class.reset_cache_key!
          reset_cache_key = described_class.cache_key

          expect(stale_cache_key).to eq(old_cache_key)
          expect(reset_cache_key).not_to eq(old_cache_key)
        end
      end
    end
  end
end
