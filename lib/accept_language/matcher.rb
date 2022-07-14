# frozen_string_literal: true

module AcceptLanguage
  # @note Compare an Accept-Language header value with your application's
  #   supported languages to find the common languages that could be presented
  #   to a user.
  # @example
  #   Matcher.new("da" => 1.0, "en-GB" => 0.8, "en" => 0.7).call(:ug, :kk, :ru, :en) # => :en
  #   Matcher.new("da" => 1.0, "en-GB" => 0.8, "en" => 0.7).call(:fr, :en, :"en-GB") # => :"en-GB"
  class Matcher
    WILDCARD = "*"

    attr_reader :excluded_langtags, :preferred_langtags

    # @param [Hash<String, BigDecimal>] languages_range A list of accepted
    #   languages with their respective qualities.
    def initialize(**languages_range)
      @excluded_langtags = ::Set[]
      langtags = []

      languages_range.select do |langtag, quality|
        if quality.zero?
          @excluded_langtags << langtag unless wildcard?(langtag)
        else
          level = (quality * 1_000).to_i
          langtags[level] = langtag
        end
      end

      @preferred_langtags = langtags.compact.reverse
    end

    # @param [Array<String, Symbol>] available_langtags The list of available
    #   languages.
    # @example Uyghur, Kazakh, Russian and English languages are available.
    #   call(:ug, :kk, :ru, :en)
    # @return [String, Symbol, nil] The language that best matches.
    def call(*available_langtags)
      available_langtags = drop_unacceptable(*available_langtags)

      preferred_langtags.each do |preferred_tag|
        if wildcard?(preferred_tag)
          langtag = any_other_langtag(*available_langtags)
          return langtag unless langtag.nil?
        else
          available_langtags.each do |available_langtag|
            return available_langtag if available_langtag.match?(/\A#{preferred_tag}/i)
          end
        end
      end

      nil
    end

    private

    def any_other_langtag(*available_langtags)
      available_langtags.find do |available_langtag|
        langtags = preferred_langtags - [WILDCARD]

        langtags.none? do |langtag|
          available_langtag.match?(/\A#{langtag}/i)
        end
      end
    end

    def drop_unacceptable(*available_langtags)
      available_langtags.inject(::Set[]) do |langtags, available_langtag|
        next langtags if unacceptable?(available_langtag)

        langtags + ::Set[available_langtag]
      end
    end

    def unacceptable?(langtag)
      excluded_langtags.any? do |excluded_langtag|
        langtag.match?(/\A#{excluded_langtag}/i)
      end
    end

    def wildcard?(value)
      value.eql?(WILDCARD)
    end
  end
end

require "set"
