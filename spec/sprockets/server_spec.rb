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
    asset = app.sprockets['complex_sprockets']
    expect(asset).to be_truthy

    assets = asset.to_a.map do |sub_asset|
      sub_asset.logical_path.gsub(/\.self\.js$/, '.js')
    end

    %w[
      base64.js
      no_requires.js
      jst_file.js
      required_tree_test/required_file1.js
      required_tree_test/required_file2.js
      file_with_directives.js
    ].each do |logical_path|
      expect(assets).to include(logical_path)
    end
  end

  describe 'source maps' do
    RSpec::Matchers.define :include_inline_source_map do
      match do |actual_response|
        actual_response.ok? &&
        actual_response.body.lines.last.start_with?('//# sourceMappingURL=data:application/json;base64,')
      end
    end

    def extract_inline_map(response)
      last_line   = response.body.lines.last
      b64_encoded = last_line.split('//# sourceMappingURL=data:application/json;base64,', 2)[1]
      json_string = Base64.decode64(b64_encoded)
      JSON.parse(json_string, symbolize_names: true)
    end

    it 'serves map for a top level file' do
      get '/assets/opal_file.js'
      expect(last_response).to include_inline_source_map

      map = extract_inline_map(last_response)

      expect(map[:sources]).to eq(['opal_file.rb']).or eq(['opal_file'])
      expect(map[:sourcesContent]).to eq(["require 'opal'\nputs 'hi from opal!'\n"])
    end

    it 'serves map for a subfolder file' do
      get '/assets/source_map/subfolder/other_file.self.js'
      expect(last_response).to include_inline_source_map

      map = extract_inline_map(last_response)

      expect(map[:sources])
        .to eq(['source_map/subfolder/other_file.rb'])
        .or eq(['source_map/subfolder/other_file'])
      expect(map[:sourcesContent]).to eq(["puts 'other!'\n"])
    end
  end
end
