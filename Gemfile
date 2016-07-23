source 'https://rubygems.org'
gemspec

if File.exist? File.expand_path('../opal')
  gem 'opal', path: '../opal'
else
  gem 'opal', github: 'opal/opal', branch: 'elia/extract-sprockets'
end
