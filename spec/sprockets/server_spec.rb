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

  it 'recompiles the asset when its dependencies change' do
    does_include = proc do |it, what, what_not=[], what_else=nil, what_else_not=nil|
      expect(it).to include what_else if what_else
      expect(it).not_to include what_else_not if what_else_not
      what.each { |i| expect(it).to include %{modules["required_tree_test/required_file#{i}"]} }
      what_not.each { |i| expect(it).not_to include %{modules["required_tree_test/required_file#{i}"]} }
    end

    ["default", "debug"].each do |pipeline|
      asset = app.sprockets['require_tree_test', pipeline: pipeline, accept: "application/javascript"]
      expect(asset).to be_truthy
      does_include.(asset.to_s, [1,2], [3], nil, "UNIQUESTRING")
      get "/assets/require_tree_test.#{pipeline}.js"
      does_include.(last_response.body, [1,2], [3], nil, "UNIQUESTRING")

      sleep 1 # Make sure to modify mtime

      File.write(__dir__+"/../fixtures/required_tree_test/required_file2.rb", "p 'UNIQUESTRING1'")

      asset = app.sprockets['require_tree_test', pipeline: pipeline, accept: "application/javascript"]
      expect(asset).to be_truthy
      does_include.(asset.to_s, [1,2], [3], "UNIQUESTRING1")
      get "/assets/require_tree_test.#{pipeline}.js"
      does_include.(last_response.body, [1,2], [3], "UNIQUESTRING1")

      sleep 1 # Make sure to modify mtime

      File.write(__dir__+"/../fixtures/required_tree_test/required_file2.rb", "p 'UNIQUESTRING2'")

      asset = app.sprockets['require_tree_test', pipeline: pipeline, accept: "application/javascript"]
      expect(asset).to be_truthy
      does_include.(asset.to_s, [1,2], [3], "UNIQUESTRING2")
      get "/assets/require_tree_test.#{pipeline}.js"
      does_include.(last_response.body, [1,2], [3], "UNIQUESTRING2")

      sleep 1 # Make sure to modify mtime

      File.write(__dir__+"/../fixtures/required_tree_test/required_file2.rb", "p 'UNIQUESTRING3'")
      File.write(__dir__+"/../fixtures/required_tree_test/required_file3.rb", "p 3")

      asset = app.sprockets['require_tree_test', pipeline: pipeline, accept: "application/javascript"]
      expect(asset).to be_truthy
      does_include.(asset.to_s, [1,2,3], [], "UNIQUESTRING3")
      get "/assets/require_tree_test.#{pipeline}.js"
      does_include.(last_response.body, [1,2], [], "UNIQUESTRING3") # fails with 3 - it doesn't get new files

      sleep 1 # Make sure to modify mtime
    ensure
      File.write(__dir__+"/../fixtures/required_tree_test/required_file2.rb", "p 2\n")
      File.unlink(__dir__+"/../fixtures/required_tree_test/required_file3.rb") rescue nil
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

      expect(map[:file]).to eq('source_map/subfolder/other_file.rb')
      expect(map[:sections].first[:map][:sources]).to eq(['other_file.source.rb'])

      expect(get(relative_path(path, map[:sections][0][:map][:sources][0])).body.chomp)
        .to eq("puts 'other!'")
    end
  end
end
