source 'https://rubygems.org'
gemspec

opal_path = File.expand_path('../opal')

if ENV['OPAL_VERSION']
  gem 'opal', ENV['OPAL_VERSION']
elsif File.exist? opal_path
  gem 'opal', path: opal_path
else
  gem 'opal', github: 'opal/opal'
end

rack_version      = ENV['RACK_VERSION']
rails_version     = ENV['RAILS_VERSION']
sprockets_version = ENV['SPROCKETS_VERSION']

gem 'rack', rack_version if rack_version
gem 'sprockets', sprockets_version if sprockets_version
gem 'rails', ENV['RAILS_VERSION'] || "~> 6.0"
