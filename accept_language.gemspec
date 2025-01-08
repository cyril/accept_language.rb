# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "accept_language"
  spec.version       = File.read("VERSION.semver").chomp
  spec.author        = "Cyril Kato"
  spec.email         = "contact@cyril.email"
  spec.summary       = "Parser for Accept-Language request HTTP header 🌐"
  spec.description   = "Parses the Accept-Language header from an HTTP " \
                       "request and produces a hash of languages and qualities."
  spec.homepage      = "https://github.com/cyril/accept_language.rb"
  spec.license       = "MIT"
  spec.files         = Dir["LICENSE.md", "README.md", "lib/**/*"]

  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "bigdecimal"
end
