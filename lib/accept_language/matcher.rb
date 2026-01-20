# frozen_string_literal: true

module AcceptLanguage
  # Matches Accept-Language header values against application-supported languages to determine
  # the optimal language choice. Handles quality values, wildcards, and language tag matching
  # according to RFC 2616 specifications.
  #
  # @api private
  # @note This class is intended for internal use by {Parser} and should not be instantiated directly.
  class Matcher
    # @api private
    WILDCARD = "*"

    # @api private
    attr_reader :excluded_langtags, :preferred_langtags

    # @api private
    def initialize(**languages_range)
      @excluded_langtags = ::Set[]
      langtags = []

      languages_range.each do |langtag, quality|
        if quality.zero?
          # Exclude specific language tags, but NOT the wildcard.
          # When "*;q=0" is specified, all non-listed languages become
          # unacceptable implicitly (they won't match any preferred_langtags).
          # Adding "*" to excluded_langtags would break prefix_match? logic.
          @excluded_langtags << langtag unless wildcard?(langtag)
        else
          langtags[quality] = langtag
        end
      end

      @preferred_langtags = langtags.compact.reverse
    end

    # @api private
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
      available_langtags.find { |tag| prefix_match?(preferred_tag, String(tag.downcase)) }
    end

    def any_other_langtag(*available_langtags)
      langtags = preferred_langtags - [WILDCARD]

      available_langtags.find do |available_langtag|
        available_downcased = available_langtag.downcase
        langtags.none? { |tag| prefix_match?(tag, String(available_downcased)) }
      end
    end

    def drop_unacceptable(*available_langtags)
      available_langtags.each_with_object(::Set[]) do |available_langtag, langtags|
        langtags << available_langtag unless unacceptable?(available_langtag)
      end
    end

    def unacceptable?(langtag)
      langtag_downcased = langtag.downcase
      excluded_langtags.any? { |excluded_tag| prefix_match?(excluded_tag, String(langtag_downcased)) }
    end

    def wildcard?(value)
      value.eql?(WILDCARD)
    end

    # Implements RFC 2616 Section 14.4 prefix matching rule:
    # "A language-range matches a language-tag if it exactly equals the tag,
    # or if it exactly equals a prefix of the tag such that the first tag
    # character following the prefix is '-'."
    #
    # @param prefix [String] The language-range to match (downcased)
    # @param tag [String] The language-tag to test (downcased)
    # @return [Boolean] true if prefix matches tag per RFC 2616 rules
    def prefix_match?(prefix, tag)
      tag == prefix || tag.start_with?("#{prefix}-")
    end
  end
end
