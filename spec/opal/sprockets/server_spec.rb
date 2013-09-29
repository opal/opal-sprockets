require 'spec_helper'

describe Opal::Server do
  it 'serves source maps only if they are enbled on the Processor' do
    original_value = Opal::Processor.source_map_enabled
    begin
      [true, false].each do |bool|
        Opal::Processor.source_map_enabled = bool
        expect(subject.source_map_enabled).to eq(bool)
      end
    ensure
      Opal::Processor.source_map_enabled = original_value
    end
  end
end
