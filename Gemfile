source 'https://rubygems.org'
gemspec

rack_version = ENV['RACK_VERSION']
opal_path = File.expand_path('../opal')

if File.exist? opal_path
  gem 'opal', path: opal_path
else
  gem 'opal', github: 'opal/opal', branch: 'elia/extract-sprockets'
end

gem 'rack', rack_version if rack_version
