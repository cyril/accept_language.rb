# frozen_string_literal: true

module AcceptLanguage
  # @example
  #   AcceptLanguage::Parser.call('da, en-gb;q=0.8, en;q=0.7') # => { da: 1.0, "en-gb": 0.8, en: 0.7 }
  # @note Parse an Accept-Language header value into a hash of tag and quality.
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  module Parser
    def self.call(raw_input, two_letter_truncate: false)
      raw_input.to_s.delete(" ").split(",").inject({}) do |hash, lang|
        tag, quality = lang.split(/;q=/i)
        next hash if tag.nil?

        tag = tag.downcase.to_sym

        if two_letter_truncate && tag.length > 2
          tag = tag[0, 2].to_sym
          next hash if hash.key?(tag)
        end

        quality = quality.nil? ? 1.0 : quality.to_f
        hash.merge(tag => quality)
      end
    end
  end
end
