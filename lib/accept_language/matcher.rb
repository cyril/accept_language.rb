# frozen_string_literal: true

module AcceptLanguage
  # A utility class that provides functionality to match the Accept-Language header value
  # against the languages supported by your application. This helps in identifying the most
  # suitable languages to present to the user based on their preferences.
  #
  # @example
  #   Matcher.new("da" => 1.0, "en-GB" => 0.8, "en" => 0.7).call(:ug, :kk, :ru, :en) # => :en
  #   Matcher.new("da" => 1.0, "en-GB" => 0.8, "en" => 0.7).call(:fr, :en, :"en-GB") # => :"en-GB"
  class Matcher
    WILDCARD = "*"

    attr_reader :primary_fallback, :excluded_langtags, :preferred_langtags

    # Initialize a new Matcher object with the languages_range parameter representing the user's
    # preferred languages and their respective quality values.
    #
    # @param [Hash<String, BigDecimal>] languages_range A hash where keys represent languages and
    #   values are the quality of preference for each language. A value of zero means the language is not acceptable.
    def initialize(primary_fallback: false, **languages_range)
      @primary_fallback = primary_fallback
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

    # Matches the user's preferred languages against the available languages of your application.
    # It prioritizes higher quality values and returns the most suitable match.
    #
    # @param [Array<String, Symbol>] available_langtags An array representing the languages available in your application.
    #
    # @example When Uyghur, Kazakh, Russian and English languages are available.
    #   call(:ug, :kk, :ru, :en)
    #
    # @return [String, Symbol, nil] The language that best matches the user's preferences, or nil if there is no match.
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

      unless primary_langtags.empty?
        available_langtags_strings = available_langtags.map(&:to_s)
        primary_langtags.each do |primary_langtag|
          return primary_langtag if available_langtags_strings.include?(primary_langtag)
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

    def primary_langtags
      return [] unless primary_fallback

      @_primary_langtags ||= begin
        langtags = ::Set[]
        preferred_langtags.each do |langtag|
          next unless (primary_langsubtag = langtag[/\A([a-z]{2})-{1}[a-zA-Z]+/, 1])

          langtags.add(primary_langsubtag)
        end
        langtags
      end
    end
  end
end
