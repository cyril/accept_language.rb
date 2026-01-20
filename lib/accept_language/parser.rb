# frozen_string_literal: true

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
    DEFAULT_QUALITY = 1000
    # @api private
    DIGIT_ZERO = "0"
    # @api private
    DOT = "."
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
    # Language tag pattern supporting BCP 47 (RFC 5646) alphanumeric subtags.
    #
    # RFC 2616 Section 3.10 references RFC 1766, which only allowed ALPHA in subtags.
    # However, BCP 47 (the current standard) permits alphanumeric subtags:
    #   subtag = 1*8alphanum
    #   alphanum = ALPHA / DIGIT
    #
    # Examples of valid BCP 47 tags with numeric subtags:
    #   - "de-CH-1996" (German, Switzerland, orthography variant 1996)
    #   - "sl-IT-nedis" (Slovenian, Italy, Nadiza dialect)
    #   - "zh-Hans-CN" (Chinese, Simplified script, China)
    LANGTAG_PATTERN = /\A(?:\*|[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*)\z/

    # @api private
    # @return [Hash<String, Integer>] Parsed language tags and their quality values (0-1000)
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
      "#{field}".downcase.delete(SPACE).split(SEPARATOR).each_with_object({}) do |lang, hash|
        tag, quality = lang.split(SUFFIX)
        next unless valid_tag?(tag)

        quality_value = parse_quality(quality)
        next if quality_value.nil?

        hash[tag] = quality_value
      end
    end

    def parse_quality(quality)
      return DEFAULT_QUALITY if quality.nil?
      return unless valid_quality?(quality)

      qvalue_to_integer(quality)
    end

    # Converts a validated qvalue string to an integer in the range 0-1000.
    #
    # The qvalue is already validated by QVALUE_PATTERN to match RFC 2616 Section 3.9:
    #   qvalue = ( "0" [ "." 0*3DIGIT ] ) | ( "1" [ "." 0*3("0") ] )
    #
    # @param quality [String] A validated qvalue string (e.g., "1", "0.8", "0.123")
    # @return [Integer] The quality value scaled to 0-1000
    #
    # @example
    #   qvalue_to_integer("1")     # => 1000
    #   qvalue_to_integer("1.0")   # => 1000
    #   qvalue_to_integer("0.8")   # => 800
    #   qvalue_to_integer("0.85")  # => 850
    #   qvalue_to_integer("0.123") # => 123
    #   qvalue_to_integer("0")     # => 0
    def qvalue_to_integer(quality)
      quality.delete(DOT).ljust(4, DIGIT_ZERO).to_i
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
