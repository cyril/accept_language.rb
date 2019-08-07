# frozen_string_literal: true

module AcceptLanguage
  # @example
  #   AcceptLanguage::Intersection.new('ja, en-gb;q=0.8, en;q=0.7', :ar, :ja).call # => :ja
  # @note Compare an Accept-Language header value with your application's
  #   supported languages to find the common languages that could be presented
  #   to a user. Option to compare only the first two letters in both the input
  #   data and the list of supported languages, or to compare them in full.
  #   Returned data is always either 'nil' or a Symbol matching an entry in the
  #   given supported languages list, without change of case; additional option
  #   available to coerce the returned result to BCP 47 capitalisation.
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  # @see https://tools.ietf.org/html/bcp47#section-2.1.1
  class Intersection
    attr_reader :parsed_tags, :supported_tags_as_given, :searchable_supported_tags

    def initialize(raw_input,
                   *supported_langs,
                   two_letter_truncate: true,
                   enforce_bcp47:       false)

      @parsed_tags = Parser.call(raw_input, two_letter_truncate: two_letter_truncate)
      @supported_tags_as_given = supported_langs.map do | lang |
        enforce_bcp47 ? Parser.bcp47(lang) : lang
      end

      # Generate one:
      #
      # * Two-letter truncated case-insensitive search list. Indices also match
      #   those in @supported_tags_as_given. Duplicate entries may be present.
      #
      # * Full tag case-insensitive search list. Indices match those in
      #   @supported_tags_as_given.
      #
      @searchable_supported_tags = supported_langs.map do |lang|
        lang = lang.downcase
        lang = lang[0, 2] if two_letter_truncate
        lang.to_sym
      end
    end

    def call
      qualities_without_zero_in_desc_order.each do |quality|
        tag = parsed_tags.key(quality)

        if wildcard?(tag)
          lang = any_tag_not_matched_by_any_other_range
          return lang unless lang.nil?
        else
          index = searchable_supported_tags.find_index(tag)
          return supported_tags_as_given[index] unless index.nil?
        end
      end

      nil
    end

  protected

    def any_tag_not_matched_by_any_other_range
      every_tag_not_matched_by_any_other_range.first
    end

    def every_tag_not_matched_by_any_other_range
      searchable_supported_tags - parsed_tags.keys
    end

    def qualities_without_zero_in_desc_order
      parsed_tags.values.reject(&:zero?).uniq.sort.reverse
    end

    def wildcard?(value)
      value.equal?(:*)
    end
  end
end

require_relative 'parser'
