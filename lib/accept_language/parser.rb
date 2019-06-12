# frozen_string_literal: true

module AcceptLanguage
  # @example
  #   Parser.new('da, en-gb;q=0.8, en;q=0.7').call
  # @note Parse a raw Accept-Language header value into an ordered list of
  #   language tags.
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  class Parser
    def initialize(raw_input)
      @string = raw_input.to_s
    end

    def call
      preferences.sort { |lang_a, lang_b| lang_b.fetch(1) <=> lang_a.fetch(1) }
                 .map(&:first)
    end

    protected

    def preferences
      @string.delete(' ').split(',').inject({}) do |result, language|
        tag, quality = language.split(/;q=/i)

        tag     = tag.downcase
        quality = quality.nil? ? 1.0 : quality.to_f

        next result if quality.zero?

        result.merge(tag.to_sym => quality)
      end
    end
  end
end
