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
    DEFAULT_QUALITY = BigDecimal("1")
    SEPARATOR = ","
    SPACE = " "
    SUFFIX = ";q="
    ALLOWED_TAG_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + ["-", "*"]
    ALLOWED_QUALITY_CHARS = ("0".."9").to_a + ["."]

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

        invalid_tag = tag.nil? || (tag.chars - ALLOWED_TAG_CHARS).any?
        invalid_quality = !quality.nil? && (quality.chars - ALLOWED_QUALITY_CHARS).any?
        next hash if invalid_tag || invalid_quality

        quality = quality.nil? ? DEFAULT_QUALITY : BigDecimal(quality)
        hash.merge(tag => quality)
      end
    end
  end
end

require_relative "matcher"
