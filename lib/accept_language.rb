# frozen_string_literal: true

# Tiny library for parsing the Accept-Language header.
module AcceptLanguage
  # @example
  #   AcceptLanguage.intersection('ja, en-gb;q=0.8, en;q=0.7', :ar, :ja) # => :ja
  def self.intersection(raw_input, *supported_langs, two_letter_truncate: true, enforce_bcp47: false)
    Intersection.new(raw_input, *supported_langs, two_letter_truncate: two_letter_truncate, enforce_bcp47: enforce_bcp47).call
  end

  # @example
  #   AcceptLanguage.parse('ja, en-gb;q=0.8, en;q=0.7') # => { ja: 1.0, "en-gb": 0.8, en: 0.7 }
  def self.parse(raw_input, two_letter_truncate: false)
    Parser.call(raw_input, two_letter_truncate: two_letter_truncate)
  end
end

require_relative 'accept_language/intersection'
