# frozen_string_literal: true

# Tiny library for parsing the Accept-Language header.
module AcceptLanguage
  def self.intersection(raw_input, *supported_languages, truncate: true)
    Intersection.new(raw_input, *supported_languages, truncate: truncate).call
  end

  def self.parse(raw_input)
    Parser.new(raw_input).call
  end
end

require_relative 'accept_language/intersection'
require_relative 'accept_language/parser'
