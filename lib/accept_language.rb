# frozen_string_literal: true

# AcceptLanguage is a lightweight library for parsing Accept-Language HTTP headers
# as defined in RFC 2616. It determines user language preferences and matches them
# against your application's supported languages.
#
# @example Basic usage
#   AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:en, :da)
#   # => :da
#
# @example With regional variants
#   AcceptLanguage.parse("fr-CH, fr;q=0.9").match(:fr, :"fr-CH")
#   # => :"fr-CH"
#
# @see https://tools.ietf.org/html/rfc2616#section-14.4
module AcceptLanguage
  # Parses an Accept-Language header field value.
  #
  # @param field [String] The Accept-Language header field value
  # @return [Parser] A parser object that responds to {Parser#match}
  #
  # @example
  #   parser = AcceptLanguage.parse("en-GB, en;q=0.9")
  #   parser.match(:en, :"en-GB") # => :"en-GB"
  def self.parse(field)
    Parser.new(field)
  end
end

require_relative File.join("accept_language", "parser")
