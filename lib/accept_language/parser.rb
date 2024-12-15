# frozen_string_literal: true

require "bigdecimal"

module AcceptLanguage
  # Parser is a utility class responsible for parsing Accept-Language header fields.
  # It processes the field to extract language tags and their respective quality values.
  #
  # @example
  #   Parser.new("da, en-GB;q=0.8, en;q=0.7")
  #   # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>1.0, "en-GB"=>0.8, "en"=>0.7}>
  #
  # @see https://tools.ietf.org/html/rfc2616#section-14.4 for more information on Accept-Language header fields.
  class Parser
    DEFAULT_QUALITY = "1"
    SEPARATOR = ","
    SPACE = " "
    SUFFIX = ";q="

    # Validates q-values according to RFC 2616:
    # - Must be between 0 and 1
    # - Can have up to 3 decimal places
    # - Allows both forms: .8 and 0.8
    QVALUE_PATTERN = /\A(?:0(?:\.[0-9]{1,3})?|1(?:\.0{1,3})?|\.[0-9]{1,3})\z/

    attr_reader :languages_range

    # Initializes a new Parser instance by importing and processing the given Accept-Language header field.
    #
    # @param [String] field The Accept-Language header field to parse.
    def initialize(field)
      @languages_range = import(field)
    end

    # Uses the Matcher class to find the best language match from the list of available languages.
    #
    # @param [Array<String, Symbol>] available_langtags An array of language tags that are available for matching.
    #
    # @example When Uyghur, Kazakh, Russian and English languages are available.
    #   match(:ug, :kk, :ru, :en)
    #
    # @return [String, Symbol, nil] The language tag that best matches the parsed languages from the Accept-Language header, or nil if no match found.
    def match(*available_langtags)
      Matcher.new(**languages_range).call(*available_langtags)
    end

    private

    # Processes the Accept-Language header field to extract language tags and their respective quality values.
    #
    # @example
    #   import('da, en-GB;q=0.8, en;q=0.7')
    #   # => {"da"=>1.0, "en-GB"=>0.8, "en"=>0.7}
    #
    # @return [Hash<String, BigDecimal>] A hash where keys represent language tags and values are their respective quality values.
    def import(field)
      "#{field}".delete(SPACE).split(SEPARATOR).inject({}) do |hash, lang|
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
      !tag.nil?
    end
  end
end

require_relative "matcher"
