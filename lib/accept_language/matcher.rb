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
      preferred_downcased = preferred_tag.downcase
      available_langtags.find { |tag| tag.downcase.start_with?(preferred_downcased) }
    end

    def any_other_langtag(*available_langtags)
      langtags = preferred_langtags - [WILDCARD]
      downcased_langtags = langtags.map(&:downcase)

      available_langtags.find do |available_langtag|
        available_downcased = available_langtag.downcase
        downcased_langtags.none? { |tag| available_downcased.start_with?(tag) }
      end
    end

    def drop_unacceptable(*available_langtags)
      available_langtags.each_with_object(::Set[]) do |available_langtag, langtags|
        langtags << available_langtag unless unacceptable?(available_langtag)
      end
    end

    def unacceptable?(langtag)
      langtag_downcased = langtag.downcase
      excluded_langtags.any? { |excluded_tag| langtag_downcased.start_with?(excluded_tag.downcase) }
    end

    def wildcard?(value)
      value.eql?(WILDCARD)
    end
  end
end
