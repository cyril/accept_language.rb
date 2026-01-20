# frozen_string_literal: true

module AcceptLanguage
  # = Language Preference Matcher
  #
  # Matcher implements the Basic Filtering matching scheme defined in
  # RFC 4647 Section 3.3.1. It takes parsed language preferences (from {Parser})
  # and determines the optimal language choice from a set of available languages.
  #
  # == Overview
  #
  # The matching process balances multiple factors:
  #
  # 1. **Quality values**: Higher q-values indicate stronger user preference
  # 2. **Declaration order**: Tie-breaker when q-values are equal
  # 3. **Prefix matching**: Allows +en+ to match +en-US+, +en-GB+, etc.
  # 4. **Wildcards**: The +*+ range matches any otherwise unmatched language
  # 5. **Exclusions**: Languages with +q=0+ are explicitly unacceptable
  #
  # == RFC 4647 Section 3.3.1 Compliance
  #
  # This implementation follows the Basic Filtering matching rules:
  #
  # > A language-range matches a language-tag if it exactly equals the tag,
  # > or if it exactly equals a prefix of the tag such that the first tag
  # > character following the prefix is "-".
  #
  # This means:
  # - +en+ matches +en+, +en-US+, +en-GB+, +en-Latn-US+
  # - +en-US+ matches only +en-US+ (not +en+ or +en-GB+)
  # - +en+ does NOT match +eng+ (no hyphen boundary)
  #
  # == Quality Value Semantics
  #
  # Quality values have specific meanings per RFC 7231 Section 5.3.1:
  #
  # - +q=1+ (or omitted): Most preferred
  # - +0 < q < 1+: Acceptable with relative preference
  # - +q=0+: Explicitly NOT acceptable
  #
  # The +q=0+ case is special: it doesn't just indicate low preference, it
  # completely excludes the language from consideration. This is used with
  # wildcards to express "any language except X":
  #
  #   Accept-Language: *, en;q=0
  #
  # == Wildcard Behavior
  #
  # The wildcard +*+ matches any language not explicitly matched by another
  # language range. This behavior is specific to HTTP, as noted in
  # RFC 4647 Section 3.3.1. When processing a wildcard:
  #
  # 1. Collect all explicitly listed language ranges (excluding the wildcard)
  # 2. Find available languages that don't match any explicit range
  # 3. Return the first such language
  #
  # This ensures explicit preferences always take priority over the wildcard.
  #
  # == Internal Design
  #
  # The Matcher separates languages into two categories during initialization:
  #
  # - **preferred_langtags**: Languages with q > 0, sorted by descending quality
  # - **excluded_langtags**: Languages with q = 0 (explicitly unacceptable)
  #
  # This separation optimizes the matching algorithm by allowing quick
  # filtering of excluded languages before attempting matches.
  #
  # == Thread Safety
  #
  # Matcher instances are immutable after initialization. Both +preferred_langtags+
  # and +excluded_langtags+ are frozen, making instances safe for concurrent use.
  #
  # @api private
  # @note This class is used internally by {Parser#match} and should not be
  #   instantiated directly. Use {AcceptLanguage.parse} followed by
  #   {Parser#match} instead.
  #
  # @example Internal usage (via Parser)
  #   # Don't do this:
  #   matcher = AcceptLanguage::Matcher.new("en" => 1000, "fr" => 800)
  #
  #   # Do this instead:
  #   AcceptLanguage.parse("en, fr;q=0.8").match(:en, :fr)
  #
  # @see Parser#match
  # @see https://www.rfc-editor.org/rfc/rfc4647#section-3.3.1 RFC 4647 Section 3.3.1 — Basic Filtering
  class Matcher
    # The hyphen character used as a subtag delimiter in language tags.
    #
    # Per RFC 4647 Section 3.3.1, prefix matching must respect hyphen boundaries.
    # A language range matches a language tag only if the character immediately
    # following the prefix is a hyphen.
    #
    # @api private
    # @return [String] "-"
    HYPHEN = "-"

    # Error message raised when an available language tag is not a Symbol.
    #
    # This guards against accidental non-Symbol values in the available languages
    # array, which would cause unexpected behavior during matching.
    #
    # @api private
    # @return [String]
    LANGTAG_TYPE_ERROR = "Language tag must be a Symbol"

    # The wildcard character that matches any language not explicitly listed.
    #
    # Per RFC 4647 Section 3.3.1, the wildcard has special semantics in HTTP:
    # - It matches any language not matched by other ranges
    # - +*;q=0+ makes all unlisted languages unacceptable
    # - It has lower effective priority than explicit language ranges
    #
    # @api private
    # @return [String] "*"
    WILDCARD = "*"

    # Language ranges explicitly marked as unacceptable (+q=0+).
    #
    # These ranges are filtered out from available languages before any
    # matching occurs. Exclusions apply via prefix matching, so excluding
    # +en+ also excludes +en-US+, +en-GB+, etc.
    #
    # @note The wildcard +*+ is never added to this set, even when +*;q=0+
    #   is specified. Wildcard exclusion is handled implicitly: when +*;q=0+
    #   and no other languages have +q > 0+, the preferred_langtags list is
    #   empty, resulting in no matches.
    #
    # @api private
    # @return [Set<String>] downcased language ranges with q=0
    #
    # @example
    #   # For "*, en;q=0, de;q=0"
    #   matcher.excluded_langtags
    #   # => #<Set: {"en", "de"}>
    attr_reader :excluded_langtags

    # Language ranges sorted by preference (descending quality value).
    #
    # This array contains only ranges with +q > 0+, ordered from most preferred
    # to least preferred. When quality values are equal, the original
    # declaration order from the Accept-Language header is preserved.
    #
    # The stable sort guarantee ensures deterministic matching: given the
    # same header and available languages, the result is always the same.
    #
    # @api private
    # @return [Array<String>] downcased language ranges, highest quality first
    #
    # @example
    #   # For "fr;q=0.8, en, de;q=0.9"
    #   # Sorted: en (q=1), de (q=0.9), fr (q=0.8)
    #   matcher.preferred_langtags
    #   # => ["en", "de", "fr"]
    attr_reader :preferred_langtags

    # Creates a new Matcher instance from parsed language preferences.
    #
    # The initialization process:
    #
    # 1. Separates excluded ranges (+q=0+) from preferred ranges (+q > 0+)
    # 2. Sorts preferred ranges by descending quality value
    # 3. Preserves original order for ranges with equal quality (stable sort)
    #
    # == Exclusion Rules
    #
    # Only specific language ranges with +q=0+ are added to the exclusion set.
    # The wildcard +*+ is explicitly NOT added even when +*;q=0+ is present,
    # because:
    #
    # - Adding +*+ to exclusions would break prefix matching logic
    # - +*;q=0+ semantics are: "no unlisted language is acceptable"
    # - This is achieved by having an empty preferred_langtags (no wildcards)
    #
    # == Stable Sorting
    #
    # Ruby's +sort_by+ is stable since Ruby 2.0, meaning elements with equal
    # sort keys maintain their relative order. This ensures that when multiple
    # languages have the same quality value, the first one declared in the
    # Accept-Language header wins.
    #
    # @api private
    # @param languages_range [Hash{String => Integer}] language ranges mapped to
    #   quality values (0-1000), as produced by {Parser}
    #
    # @example
    #   Matcher.new("en" => 1000, "fr" => 800, "de" => 0)
    #   # preferred_langtags: ["en", "fr"]
    #   # excluded_langtags: #<Set: {"de"}>
    def initialize(**languages_range)
      @excluded_langtags = ::Set[]

      languages_range.each do |langtag, quality|
        next unless quality.zero? && !wildcard?(langtag)

        # Exclude specific language ranges, but NOT the wildcard.
        # When "*;q=0" is specified, all non-listed languages become
        # unacceptable implicitly (they won't match any preferred_langtags).
        # Adding "*" to excluded_langtags would break prefix_match? logic.
        @excluded_langtags << langtag
      end

      # Sort by descending quality. Ruby's sort_by is stable, so languages
      # with identical quality values preserve their original order from
      # the Accept-Language header (first declared = higher priority).
      @preferred_langtags = languages_range
                            .reject { |_, quality| quality.zero? }
                            .sort_by { |_, quality| -quality }
                            .map(&:first)
    end

    # Finds the best matching language from the available options.
    #
    # == Algorithm
    #
    # 1. **Filter**: Remove available languages that match any excluded range
    # 2. **Match**: For each preferred range (in quality order):
    #    - If it's a wildcard, return the first available language not
    #      matching any other preferred range
    #    - Otherwise, return the first available language that matches
    #      via exact match or prefix match
    # 3. **Result**: Return the first match found, or +nil+ if none
    #
    # == Return Value
    #
    # The returned value preserves the exact form (case) of the matched
    # element from +available_langtags+. This is important for direct use
    # with APIs like +I18n.locale=+ that may be case-sensitive.
    #
    # @api private
    # @param available_langtags [Array<Symbol>] languages to match against
    # @return [Symbol, nil] the best matching language, or +nil+
    # @raise [TypeError] if any available language tag is not a Symbol
    #
    # @example Basic matching
    #   matcher = Matcher.new("en" => 1000, "fr" => 800)
    #   matcher.call(:en, :fr, :de)
    #   # => :en
    #
    # @example Prefix matching
    #   matcher = Matcher.new("en" => 1000)
    #   matcher.call(:"en-US", :"en-GB")
    #   # => :"en-US"
    #
    # @example With exclusion
    #   matcher = Matcher.new("*" => 500, "en" => 0)
    #   matcher.call(:en, :fr)
    #   # => :fr
    def call(*available_langtags)
      filtered_tags = drop_unacceptable(*available_langtags)
      return if filtered_tags.empty?

      find_best_match(filtered_tags)
    end

    private

    # Iterates through preferred language ranges to find the first match.
    #
    # @param available_langtags [Set<String>] pre-filtered available tags
    # @return [Symbol, nil] the matched tag or nil
    def find_best_match(available_langtags)
      preferred_langtags.each do |preferred_tag|
        match = match_langtag(preferred_tag, available_langtags)
        return :"#{match}" unless match.nil?
      end

      nil
    end

    # Attempts to match a single preferred range against available languages.
    #
    # Handles both wildcard and specific language ranges differently.
    #
    # @param preferred_tag [String] the preferred language range to match
    # @param available_langtags [Set<String>] available tags to search
    # @return [String, nil] the matched tag or nil
    def match_langtag(preferred_tag, available_langtags)
      if wildcard?(preferred_tag)
        any_other_langtag(*available_langtags)
      else
        find_matching_tag(preferred_tag, available_langtags)
      end
    end

    # Finds an available language that matches via exact or prefix match.
    #
    # @param preferred_tag [String] the preferred range (downcased)
    # @param available_langtags [Set<String>] available tags
    # @return [String, nil] the first matching tag or nil
    def find_matching_tag(preferred_tag, available_langtags)
      available_langtags.find { |tag| prefix_match?(preferred_tag, tag) }
    end

    # Finds an available language for wildcard matching.
    #
    # Returns the first available language that doesn't match any explicitly
    # listed preferred language range. This implements the HTTP-specific
    # wildcard semantics defined in RFC 4647 Section 3.3.1, where +*+ matches
    # "any language not matched by another range".
    #
    # @param available_langtags [Array<String>] available tags
    # @return [String, nil] the first non-matching tag or nil
    def any_other_langtag(*available_langtags)
      langtags = preferred_langtags - [WILDCARD]

      available_langtags.find do |available_langtag|
        langtags.none? { |tag| prefix_match?(tag, available_langtag) }
      end
    end

    # Removes explicitly excluded languages from the available set.
    #
    # Uses prefix matching for exclusions, so excluding +en+ also excludes
    # +en-US+, +en-GB+, etc.
    #
    # @param available_langtags [Array<Symbol>] all available tags
    # @return [Set<String>] tags not matching any exclusion
    # @raise [TypeError] if any tag is not a Symbol
    def drop_unacceptable(*available_langtags)
      available_langtags.each_with_object(::Set[]) do |available_langtag, langtags|
        raise ::TypeError, LANGTAG_TYPE_ERROR unless available_langtag.is_a?(::Symbol)

        available_langtag = "#{available_langtag}"
        langtags << available_langtag unless unacceptable?(available_langtag)
      end
    end

    # Checks if a language tag is explicitly excluded.
    #
    # @param langtag [String] the tag to check (as string)
    # @return [Boolean] true if the tag matches any exclusion
    def unacceptable?(langtag)
      excluded_langtags.any? { |excluded_tag| prefix_match?(excluded_tag, langtag) }
    end

    # Checks if a value is the wildcard character.
    #
    # @param value [String] the value to check
    # @return [Boolean] true if the value is "*"
    def wildcard?(value)
      value.eql?(WILDCARD)
    end

    # Implements RFC 4647 Section 3.3.1 Basic Filtering prefix matching rule.
    #
    # From the specification:
    #
    # > A language-range matches a language-tag if it exactly equals the tag,
    # > or if it exactly equals a prefix of the tag such that the first tag
    # > character following the prefix is "-".
    #
    # This rule ensures that language ranges match at subtag boundaries:
    #
    # - +en+ matches +en+ (exact)
    # - +en+ matches +en-US+ (prefix + hyphen)
    # - +en+ does NOT match +eng+ (no hyphen after prefix)
    # - +en-US+ does NOT match +en+ (range is longer than tag)
    #
    # Matching is case-insensitive per RFC 4647 Section 2, using +casecmp?+
    # for efficient comparison without allocating new strings.
    #
    # @param range [String] the language range to match (downcased)
    # @param tag [String] the language tag to test (any case)
    # @return [Boolean] true if range matches tag per RFC 4647 rules
    #
    # @example Exact matches
    #   prefix_match?("en", "en")       # => true
    #   prefix_match?("en", "EN")       # => true
    #   prefix_match?("en-us", "en-US") # => true
    #
    # @example Prefix matches
    #   prefix_match?("en", "en-us")    # => true
    #   prefix_match?("en", "en-GB")    # => true
    #   prefix_match?("zh", "zh-Hant-TW") # => true
    #
    # @example Non-matches
    #   prefix_match?("en-us", "en")    # => false (range longer than tag)
    #   prefix_match?("en", "eng")      # => false (no hyphen boundary)
    #   prefix_match?("en", "fr")       # => false (different language)
    def prefix_match?(range, tag)
      return true if tag.casecmp?(range)
      return false if tag.length <= range.length

      tag[0, range.length].casecmp?(range) && tag[range.length] == HYPHEN
    end
  end
end
