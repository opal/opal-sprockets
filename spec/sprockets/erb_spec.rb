require 'spec_helper'
require 'opal/sprockets/erb'

describe Opal::Sprockets::ERB do
  let(:pathname) { Pathname("/Code/app/mylib/opal/foo.#{ext}") }
  let(:data) { %{<% print("") %><a href="<%= url %>"><%= name %></a>} }
  let(:input) { {
    environment: Opal::Sprockets::Environment.new.tap {|e| e.append_path "/Code/app/mylib/opal"},
    data: data,
    filename: pathname.to_s,
    load_path: "/Code/app/mylib/opal",
    metadata: {},
    cache: Sprockets::Cache.new
  } }
  let(:ext) { 'opalerb' }

  it 'renders the template' do
    result = described_class.call(input)

    expect(result[:data]).to include('"<a href=\""')
  end

  it 'implicitly requires "erb"' do
    result = described_class.call(input)

    expect(result[:required].first).to include("stdlib/erb.rb")
  end
end
