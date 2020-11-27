require 'bundler'
Bundler.require

RSpec.configure do |config|
  config.before do
    Opal::Config.reset!
    Opal::Sprockets::Processor.reset_cache_key!
  end
end
