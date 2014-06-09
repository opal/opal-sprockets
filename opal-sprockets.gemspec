# -*- encoding: utf-8 -*-
require File.expand_path('../lib/opal/sprockets/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'opal-sprockets'
  s.version      = Opal::Sprockets::VERSION
  s.author       = 'Adam Beynon'
  s.email        = 'adam.beynon@gmail.com'
  s.homepage     = 'http://opalrb.org'
  s.summary      = 'Sprockets support for opal'
  s.description  = 'Sprockets suppoer for opal.'

  s.files          = `git ls-files`.split("\n")
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ['lib']

  s.add_dependency 'sprockets'
  s.add_dependency 'opal', '~> 0.6.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
