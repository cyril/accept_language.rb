# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'accept_language'
  spec.version       = File.read('VERSION.semver').chomp
  spec.authors       = ['Cyril Kato']
  spec.email         = ['contact@cyril.email']

  spec.summary       = 'Parser for Accept-Language request HTTP header'
  spec.description   = 'Parses the Accept-Language header from an HTTP ' \
                       'request and produces a hash of languages and qualities.'
  spec.homepage      = 'https://github.com/cyril/accept_language.rb'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',    '~> 2.0'
  spec.add_development_dependency 'rake',       '~> 10.0'
  spec.add_development_dependency 'rspec',      '~> 3.0'
  spec.add_development_dependency 'rubocop',    '~> 0.71'
  spec.add_development_dependency 'simplecov',  '~> 0.16'
  spec.add_development_dependency 'yard',       '~> 0.9'
end
