# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'accept_language'
  spec.version       = File.read('VERSION.semver').chomp
  spec.author        = 'Cyril Kato'
  spec.email         = 'contact@cyril.email'
  spec.summary       = 'Parser for Accept-Language request HTTP header'
  spec.description   = 'Parses the Accept-Language header from an HTTP ' \
                       'request and produces a hash of languages and qualities.'
  spec.homepage      = 'https://github.com/cyril/accept_language.rb'
  spec.license       = 'MIT'
  spec.files         = Dir['LICENSE.md', 'README.md', 'lib/**/*']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-thread_safety'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
