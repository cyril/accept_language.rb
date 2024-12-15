# frozen_string_literal: true

module AcceptLanguage
  # Matches Accept-Language header values against application-supported languages to determine
  # the optimal language choice. Handles quality values, wildcards, and language tag matching
  # according to RFC 2616 specifications.
  #
  # @example
  #   Matcher.new("da" => 1.0, "en-GB" => 0.8, "en" => 0.7).call(:ug, :kk, :ru, :en) # => :en
  #   Matcher.new("da" => 1.0, "en-GB" => 0.8, "en" => 0.7).call(:fr, :en, :"en-GB") # => :"en-GB"
  class Matcher
    WILDCARD = "*"

    attr_reader :excluded_langtags, :preferred_langtags

    # Initialize a new Matcher object with the languages_range parameter representing the user's
    # preferred languages and their respective quality values.
    #
    # @param [Hash<String, BigDecimal>] languages_range A hash where keys represent languages and
    #   values are the quality of preference for each language. A value of zero means the language is not acceptable.
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

    # Finds the optimal language match by comparing user preferences against available languages.
    # Handles priorities based on:
    # 1. Explicit quality values (q-values)
    # 2. Language tag specificity (exact matches preferred over partial matches)
    # 3. Order of preference in the original Accept-Language header
    #
    # @param [Array<String, Symbol>] available_langtags Languages supported by your application
    # @return [String, Symbol, nil] Best matching language or nil if no acceptable match found
    # @raise [ArgumentError] If any language tag is nil
    def call(*available_langtags)
      raise ::ArgumentError, "Language tags cannot be nil" if available_langtags.any?(&:nil?)

      filtered_tags = drop_unacceptable(*available_langtags)
      return nil if filtered_tags.empty?

      find_best_match(filtered_tags)
    end

    private

    def find_best_match(available_langtags)
      preferred_langtags.each do |preferred_tag|
        match = match_langtag(preferred_tag, available_langtags)
        return match if match
      end

      nil
    end

    def match_langtag(preferred_tag, available_langtags)
      if wildcard?(preferred_tag)
        any_other_langtag(*available_langtags)
      else
        find_matching_tag(preferred_tag, available_langtags)
      end
    end

    def find_matching_tag(preferred_tag, available_langtags)
      available_langtags.find { |tag| tag.match?(/\A#{preferred_tag}/i) }
    end

    def any_other_langtag(*available_langtags)
      available_langtags.find do |available_langtag|
        langtags = preferred_langtags - [WILDCARD]
        langtags.none? { |tag| available_langtag.match?(/\A#{tag}/i) }
      end
    end

    def drop_unacceptable(*available_langtags)
      available_langtags.inject(::Set[]) do |langtags, available_langtag|
        next langtags if unacceptable?(available_langtag)

        langtags + ::Set[available_langtag]
      end
    end

    def unacceptable?(langtag)
      excluded_langtags.any? { |excluded_tag| langtag.match?(/\A#{excluded_tag}/i) }
    end

    def wildcard?(value)
      value.eql?(WILDCARD)
    end
  end
end
