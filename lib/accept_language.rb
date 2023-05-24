# frozen_string_literal: true

# This module provides a tiny library for parsing the Accept-Language header as specified in RFC 2616.
# It transforms the Accept-Language header field into a language range, providing a flexible way to determine
# user's language preferences and match them with the available languages in your application.
#
# @example
#   AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")
#   # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>1.0, "en-GB"=>0.8, "en"=>0.7}>
#
# @see https://tools.ietf.org/html/rfc2616#section-14.4
module AcceptLanguage
  # Parses an Accept-Language header field value into a Parser object, which can then be used to match
  # user's preferred languages against the languages your application supports.
  # This method accepts a string argument in the format as described in RFC 2616 Section 14.4, and returns
  # a Parser object which responds to the #match method.
  #
  # @param field [String] the Accept-Language header field value.
  #
  # @example
  #   AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")
  #   # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>1.0, "en-GB"=>0.8, "en"=>0.7}>
  #
  # @return [Parser] a Parser object that responds to #match method.
  def self.parse(field)
    Parser.new(field)
  end
end

# Load the Parser class
require_relative File.join("accept_language", "parser")
