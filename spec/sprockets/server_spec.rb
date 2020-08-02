require 'spec_helper'
require 'sourcemap'
require 'rack/test'

describe Opal::Sprockets::Server do
  include Rack::Test::Methods

  def app
    described_class.new { |s|
      s.main = 'opal'
      s.debug = false
      s.append_path File.expand_path('../../fixtures', __FILE__)
      s.sprockets.logger = Logger.new(nil)
    }
  end

  it 'serves assets from /assets' do
    get '/assets/opal.js'
    expect(last_response).to be_ok
  end

  it 'serves assets with complex sprockets requires' do
    asset = app.sprockets['complex_sprockets', accept: "application/javascript"]
    expect(asset).to be_truthy

    assets = asset.metadata[:included].map do |sub_asset|
      URI.parse(sub_asset).path.split(%r'/fixtures/|/stdlib/').last
    end

    %w[
      base64.rb
      no_requires.rb
      jst_file.jst.ejs
      required_tree_test/required_file1.rb
      required_tree_test/required_file2.rb
      file_with_directives.js
    ].each do |logical_path|
      expect(assets).to include(logical_path)
    end
  end

  describe 'source maps' do
    RSpec::Matchers.define :include_source_map do
      match do |actual_response|
        actual_response.ok? &&
        actual_response.body.lines.last.start_with?('//# sourceMappingURL=')
      end
    end

    def extract_map(path, response)
      last_line   = response.body.lines.last
      if last_line.start_with? "//# sourceMappingURL=data:application/json;base64,"
        b64_encoded = last_line.split('//# sourceMappingURL=data:application/json;base64,', 2)[1]
        json_string = Base64.decode64(b64_encoded)
      else
        map_file = last_line.split('//# sourceMappingURL=', 2)[1].chomp
        map_file = relative_path(path, map_file)
        map_file = get map_file
        json_string = map_file.body
      end
      JSON.parse(json_string, symbolize_names: true)
    end

    def relative_path(path, file)
      URI.join("http://example.com/", path, file).path
    end

    it 'serves map for a top level file' do
      path = '/assets/opal_file.debug.js'
      get path
      expect(last_response).to include_source_map

      map = extract_map(path, last_response)

      # Doesn't apply to Sprockets 4.0 map generation
      #
      #expect(map[:sources]).to eq(['opal_file.rb']).or eq(['opal_file'])
      #expect(map[:sourcesContent]).to eq(["require 'opal'\nputs 'hi from opal!'\n"])

      expect(map[:file]).to eq('opal_file.rb')
      expect(map[:sections].last[:map][:sources]).to eq(['opal_file.source.rb'])

      expect(get(relative_path(path, map[:sections].last[:map][:sources][0])).body.chomp)
        .to eq("require 'opal'\nputs 'hi from opal!'")
    end

    it 'serves map for a subfolder file' do
      path = '/assets/source_map/subfolder/other_file.debug.js'
      get path
      expect(last_response).to include_source_map

      map = extract_map(path, last_response)

      # Doesn't apply to Sprockets 4.0 map generation
      #
      #expect(map[:sources])
      #  .to eq(['source_map/subfolder/other_file.rb'])
      #  .or eq(['source_map/subfolder/other_file'])

      expect(map[:file]).to eq('source_map/subfolder/other_file.rb')
      expect(map[:sections].first[:map][:sources]).to eq(['other_file.source.rb'])

      expect(get(relative_path(path, map[:sections][0][:map][:sources][0])).body.chomp)
        .to eq("puts 'other!'")
    end
  end
end
