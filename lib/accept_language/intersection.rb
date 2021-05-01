# frozen_string_literal: true

module AcceptLanguage
  # @example
  #   AcceptLanguage::Intersection.new('ja, en-gb;q=0.8, en;q=0.7', :ar, :ja).call # => :ja
  # @note Compare an Accept-Language header value with your application's
  #   supported languages to find the common languages that could be presented
  #   to a user.
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  class Intersection
    attr_reader :preferences, :supported_langs

    def initialize(raw_input, *supported_langs, two_letter_truncate: true)
      @preferences = Parser.call(raw_input, two_letter_truncate: two_letter_truncate)

      @supported_langs = supported_langs.map do |lang|
        lang = lang.downcase
        lang = lang[0, 2] if two_letter_truncate
        lang.to_sym
      end.uniq
    end

    def call
      qualities_without_zero_in_desc_order.each do |quality|
        tag = preferences.key(quality)

        if wildcard?(tag)
          lang = any_tag_not_matched_by_any_other_range
          return lang unless lang.nil?
        end

        return tag if supported_langs.include?(tag)
      end

      nil
    end

    protected

    def any_tag_not_matched_by_any_other_range
      every_tag_not_matched_by_any_other_range.first
    end

    def every_tag_not_matched_by_any_other_range
      supported_langs - preferences.keys
    end

    def qualities_without_zero_in_desc_order
      preferences.values.reject(&:zero?).uniq.sort.reverse
    end

    def wildcard?(value)
      value.equal?(:*)
    end
  end
end

require_relative "parser"
