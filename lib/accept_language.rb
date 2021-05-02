# frozen_string_literal: true

# Tiny library for parsing the Accept-Language header.
# @example
#   AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7") # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>0.1e1, "en-GB"=>0.8e0, "en"=>0.7e0}>
# @see https://tools.ietf.org/html/rfc2616#section-14.4
module AcceptLanguage
  # @note Parse an Accept-Language header field into a language range.
  # @example
  #   parse("da, en-GB;q=0.8, en;q=0.7") # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>0.1e1, "en-GB"=>0.8e0, "en"=>0.7e0}>
  # @return [#match] a parser that responds to #match.
  def self.parse(field)
    Parser.new(field)
  end
end

require_relative "accept_language/parser"
