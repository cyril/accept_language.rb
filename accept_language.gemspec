# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "accept_language"
  spec.version       = File.read("VERSION.semver").chomp
  spec.author        = "Cyril Kato"
  spec.email         = "contact@cyril.email"
  spec.summary       = "Parser for Accept-Language request HTTP header"
  spec.description   = "A lightweight, thread-safe Ruby library for parsing " \
                       "the Accept-Language HTTP header as defined in RFC 2616, " \
                       "with full support for BCP 47 language tags."
  spec.homepage      = "https://github.com/cyril/accept_language.rb"
  spec.license       = "MIT"
  spec.files         = Dir["LICENSE.md", "README.md", "lib/**/*"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "source_code_uri"       => "https://github.com/cyril/accept_language.rb",
    "documentation_uri"     => "https://rubydoc.info/github/cyril/accept_language.rb/main",
    "bug_tracker_uri"       => "https://github.com/cyril/accept_language.rb/issues",
    "wiki_uri"              => "https://github.com/cyril/accept_language.rb/wiki"
  }
end
