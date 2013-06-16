require 'spec_helper'

describe Opal::Processor do
  let(:processor) do
    Opal::Processor.new(File.expand_path('spec/fixtures/app/foo.rb'))
  end

  let(:sprockets) do
    Sprockets::Environment.new.tap do |s|
      s.append_path 'spec/fixtures/app'
      s.append_path 'spec/fixtures/app2'
    end
  end

  describe "#find_opal_require" do
    it "returns the full path of a matching ruby file" do
      processor.find_opal_require(sprockets, 'foo').should eq(File.expand_path('spec/fixtures/app/foo.rb'))
    end

    it "returns original asset name if no matching ruby file" do
      processor.find_opal_require(sprockets, 'doesnt_exist').should eq("doesnt_exist")
    end

    it "only matches ruby files (not js files)" do
      processor.find_opal_require(sprockets, "bar").should eq("bar")
    end
  end
end
