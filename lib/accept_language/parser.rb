# frozen_string_literal: true

module AcceptLanguage
  # @note Parser for Accept-Language header fields.
  # @example
  #   Parser.new("da, en-GB;q=0.8, en;q=0.7") # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>0.1e1, "en-GB"=>0.8e0, "en"=>0.7e0}>
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  class Parser
    attr_reader :languages_range

    # @param [String] field The Accept-Language header field to parse.
    # @see https://tools.ietf.org/html/rfc2616#section-14.4
    def initialize(field)
      @languages_range = import(field)
    end

    # @param [Array<String, Symbol>] available_langtags The list of available
    #   languages.
    # @example Uyghur, Kazakh, Russian and English languages are available.
    #   match(:ug, :kk, :ru, :en)
    # @return [String, Symbol, nil] The language that best matches.
    def match(*available_langtags)
      Matcher.new(**languages_range).call(*available_langtags)
    end

    private

    # @example
    #   import('da, en-GB;q=0.8, en;q=0.7') # => {"da"=>0.1e1, "en-GB"=>0.8e0, "en"=>0.7e0}
    # @return [Hash<String, BigDecimal>] A list of accepted languages with their
    #   respective qualities.
    def import(field)
      field.delete(" ").split(",").inject({}) do |hash, lang|
        tag, quality = lang.split(/;q=/i)
        next hash if tag.nil?

        quality = quality.nil? ? BigDecimal("1") : BigDecimal(quality)
        hash.merge(tag => quality)
      end
    end
  end
end

require "bigdecimal"
require_relative "matcher"
