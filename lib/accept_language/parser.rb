# frozen_string_literal: true

require "bigdecimal"

module AcceptLanguage
  # Parses Accept-Language header fields into structured data, extracting language tags
  # and their quality values (q-values). Validates input according to RFC 2616 specifications
  # and handles edge cases like malformed inputs and implicit quality values.
  #
  # @example
  #   parser = Parser.new("da, en-GB;q=0.8, en;q=0.7")
  #   parser.match(:en, :da) # => :da
  #
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  class Parser
    # @api private
    DEFAULT_QUALITY = "1"
    # @api private
    SEPARATOR = ","
    # @api private
    SPACE = " "
    # @api private
    SUFFIX = ";q="
    # @api private
    # RFC 2616 Section 3.9 qvalue syntax:
    #   qvalue = ( "0" [ "." 0*3DIGIT ] ) | ( "1" [ "." 0*3("0") ] )
    QVALUE_PATTERN = /\A(?:0(?:\.[0-9]{1,3})?|1(?:\.0{1,3})?)\z/
    # @api private
    LANGTAG_PATTERN = /\A(?:\*|[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*)\z/

    # @api private
    # @return [Hash<String, BigDecimal>] Parsed language tags and their quality values
    attr_reader :languages_range

    # Initializes a new Parser instance by importing and processing the given Accept-Language header field.
    #
    # @param field [String] The Accept-Language header field to parse.
    def initialize(field)
      @languages_range = import(field)
    end

    # Finds the best matching language from available options based on user preferences.
    # Considers quality values and language tag specificity (e.g., "en-US" vs "en").
    #
    # @param available_langtags [Array<String, Symbol>] Languages supported by your application
    # @return [String, Symbol, nil] Best matching language tag or nil if no match found
    #
    # @example Match against specific language options
    #   parser.match("en", "fr", "de") # => "en" if English is preferred
    # @example Match with region-specific tags
    #   parser.match("en-US", "en-GB", "fr") # => "en-GB" if British English is preferred
    def match(*available_langtags)
      Matcher.new(**languages_range).call(*available_langtags)
    end

    private

    def import(field)
      "#{field}".downcase.delete(SPACE).split(SEPARATOR).inject({}) do |hash, lang|
        tag, quality = lang.split(SUFFIX)
        next hash unless valid_tag?(tag)

        quality = DEFAULT_QUALITY if quality.nil?
        next hash unless valid_quality?(quality)

        hash.merge(tag => BigDecimal(quality))
      end
    end

    def valid_quality?(quality)
      quality.match?(QVALUE_PATTERN)
    end

    def valid_tag?(tag)
      return false if tag.nil?

      tag.match?(LANGTAG_PATTERN)
    end
  end
end

require_relative "matcher"
