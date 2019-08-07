# frozen_string_literal: true

module AcceptLanguage
  # @example
  #   AcceptLanguage::Parser.call('da, en-gb;q=0.8, en;q=0.7') # => { da: 1.0, "en-gb": 0.8, en: 0.7 }
  # @note Parse an Accept-Language header value into a hash of tag and quality.
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  module Parser
    def self.call(raw_input, two_letter_truncate: false)
      raw_input.to_s.delete(' ').split(',').inject({}) do |hash, lang|
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

    # Apply BCP 47 capitalisation rules to a given language tag. This may be
    # useful for some, but could be intrusive for Rails I18n.
    #
    #   https://tools.ietf.org/html/bcp47#section-2.1.1
    #   https://github.com/svenfuchs/rails-i18n/issues/282
    #
    # > All subtags, including extension and private use subtags, use lowercase
    # > letters with two exceptions: two-letter and four-letter subtags that
    # > neither appear at the start of the tag nor occur after singletons. Such
    # > two-letter subtags are all uppercase (as in the tags "en-CA-x-ca" or
    # > "sgn-BE-FR") and four-letter subtags are titlecase (as in the tag
    # > "az-Latn-x-latn").
    #
    # Accepts String or Symbol input; Symbols always returned.
    #
    def self.bcp47(tag)
      tag   ||= ''
      rebuilt = []
      subtags = tag.to_s.split('-')

      subtags.each_with_index do | subtag, index |

        # All subtags...use lowercase...except...unless...appear at the start
        # of the tag...
        #
        if index == 0
          rebuilt << subtag.downcase

        else

          # All subtags...use lowercase...except...unless...occur after
          # singletons.
          #
          if subtags[index - 1].length == 1
            rebuilt << subtag.downcase

          # ...use lowercase...except...two-letter subtags are alll uppercase
          # ...and four-letter subtags are titlecase.
          #
          else
            if subtag.length == 2
              rebuilt << subtag.upcase
            elsif subtag.length == 4
              rebuilt << "#{ subtag[0].upcase }#{ subtag[1..-1].downcase }"
            else
              rebuilt << subtag.downcase
            end

          end
        end
      end

      return rebuilt.join('-').to_sym
    end
  end
end
