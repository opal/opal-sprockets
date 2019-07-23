require 'spec_helper'
require 'opal/sprockets'

describe Opal::Sprockets do
  let(:env) { Sprockets::Environment.new }
  before { Opal.paths.each { |path| env.append_path path } }

  describe '.load_asset' do
    it 'loads the main asset' do
      code = described_class.load_asset('console')
      expect(code).to include('Opal.require("console");')
    end

    it 'marks as loaded stubs and all non-opal assets' do
      allow(Opal::Config).to receive(:stubbed_files) { %w[foo bar] }

      code = described_class.load_asset('baz')
      expect(code).to include('Opal.loaded(["foo","bar"].concat(OpalLoaded || []));')
      expect(code).to include('Opal.require("baz");')
    end

    it 'tries to load an asset if it is registered as opal module' do
      code = described_class.load_asset('foo')
      expect(code).to include('Opal.require("foo");')
    end

    it 'warns the user that passing an env is not needed, only once' do
      expect(described_class).to receive(:warn).once
      described_class.load_asset('foo', env)
      described_class.load_asset('foo', env)
      described_class.load_asset('foo', env)
      described_class.load_asset('foo', 'bar', env)
      described_class.load_asset('foo', 'bar', env)
    end

    it 'accepts multiple names' do
      code = described_class.load_asset('foo', 'bar')
      expect(code).to include('Opal.require("foo");')
      expect(code).to include('Opal.require("bar");')
    end

    it 'detects deprecated env with multiple names' do
      code = described_class.load_asset('foo', 'bar', env)
      expect(code).to eq([
        'Opal.loaded(OpalLoaded || []);',
        'Opal.require("foo");',
        'Opal.require("bar");',
      ].join("\n"))
    end
  end

  describe '.javascript_include_tag' do
    it 'works with trailing / in the prefix' do
      code = described_class.javascript_include_tag('corelib/runtime', prefix: '/', sprockets: env, debug: false)
      expect(code).to include('src="/corelib/runtime.')
      expect(code).not_to include('//')
    end
  end
end
