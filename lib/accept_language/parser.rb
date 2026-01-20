# frozen_string_literal: true

module AcceptLanguage
  # = Accept-Language Header Parser
  #
  # Parser handles the parsing of +Accept-Language+ HTTP header field values
  # as defined in RFC 2616 Section 14.4. It extracts language tags and their
  # associated quality values (q-values), validates them according to the
  # specification, and provides matching capabilities against application-
  # supported languages.
  #
  # == Overview
  #
  # The +Accept-Language+ header field value consists of a comma-separated
  # list of language ranges, each optionally accompanied by a quality value
  # indicating relative preference. This parser:
  #
  # 1. Tokenizes the header into individual language-range entries
  # 2. Extracts and validates language tags per BCP 47
  # 3. Extracts and validates quality values per RFC 2616 Section 3.9
  # 4. Stores valid entries for subsequent matching operations
  #
  # == Quality Values (q-values)
  #
  # Quality values express the user's relative preference for a language.
  # Per RFC 2616 Section 3.9, the syntax is:
  #
  #   qvalue = ( "0" [ "." 0*3DIGIT ] ) | ( "1" [ "." 0*3("0") ] )
  #
  # This means:
  # - Values range from +0.000+ to +1.000+
  # - Maximum of 3 decimal places
  # - +0+ indicates "not acceptable"
  # - +1+ indicates "most preferred" (default when omitted)
  #
  # Examples of valid q-values: +0+, +0.5+, +0.75+, +0.123+, +1+, +1.0+, +1.000+
  #
  # Examples of invalid q-values (silently ignored): +1.5+, +0.1234+, +-0.5+, +.5+
  #
  # == Language Tags
  #
  # Language tags follow the BCP 47 specification (RFC 5646), which supersedes
  # the RFC 1766 reference in RFC 2616 Section 3.10. Valid tags consist of:
  #
  # - A primary subtag of 1-8 alphabetic characters (e.g., +en+, +zh+, +ast+)
  # - Zero or more subtags of 1-8 alphanumeric characters, separated by hyphens
  # - The special wildcard tag +*+ (matches any language)
  #
  # Examples of valid language tags:
  # - +en+ (English)
  # - +en-US+ (English, United States)
  # - +zh-Hant-TW+ (Chinese, Traditional script, Taiwan)
  # - +de-CH-1996+ (German, Switzerland, 1996 orthography)
  # - +sr-Latn+ (Serbian, Latin script)
  # - +*+ (wildcard)
  #
  # == Internal Representation
  #
  # Internally, quality values are stored as integers in the range 0-1000
  # (multiplied by 1000) to avoid floating-point comparison issues. This is
  # an implementation detail and does not affect the public API.
  #
  # == Thread Safety
  #
  # Parser instances are immutable after initialization. The +languages_range+
  # hash is frozen, making Parser instances safe to share between threads.
  #
  # == Error Handling
  #
  # The parser is lenient by design to handle real-world headers that may
  # not strictly conform to specifications:
  #
  # - Invalid language tags are silently skipped
  # - Invalid quality values cause the entry to be skipped
  # - Empty or +nil+ input results in an empty languages_range
  # - Malformed entries (missing separators, etc.) are skipped
  #
  # However, the parser is strict about input types: only +String+ or +nil+
  # are accepted for the +field+ parameter.
  #
  # @example Basic usage
  #   parser = AcceptLanguage::Parser.new("da, en-GB;q=0.8, en;q=0.7")
  #   parser.match(:en, :da)
  #   # => :da
  #
  # @example Inspecting parsed languages
  #   parser = AcceptLanguage::Parser.new("fr-CH;q=0.9, fr;q=0.8, en;q=0.7")
  #   parser.languages_range
  #   # => {"fr-ch"=>900, "fr"=>800, "en"=>700}
  #
  # @example Handling wildcards
  #   parser = AcceptLanguage::Parser.new("de, *;q=0.5")
  #   parser.match(:ja, :de)
  #   # => :de
  #
  # @example Handling exclusions
  #   parser = AcceptLanguage::Parser.new("*, en;q=0")
  #   parser.match(:en, :fr)
  #   # => :fr
  #
  # @see AcceptLanguage.parse
  # @see Matcher
  # @see https://tools.ietf.org/html/rfc2616#section-14.4 RFC 2616 Section 14.4
  # @see https://tools.ietf.org/html/rfc2616#section-3.9 RFC 2616 Section 3.9 (qvalue)
  # @see https://tools.ietf.org/html/bcp47 BCP 47
  class Parser
    # Default quality value (1.0) scaled to internal integer representation.
    #
    # When a language tag appears without an explicit quality value, it is
    # assigned this default value, indicating maximum preference.
    #
    # @api private
    # @return [Integer] 1000 (representing q=1.0)
    DEFAULT_QUALITY = 1_000

    # The ASCII digit zero character, used in quality value parsing.
    #
    # @api private
    # @return [String] "0"
    DIGIT_ZERO = "0"

    # The decimal point character, used in quality value parsing.
    #
    # @api private
    # @return [String] "."
    DOT = "."

    # Error message raised when +field+ argument is not a String or nil.
    #
    # This guards against accidental non-String values being passed to the
    # parser, which would cause unexpected behavior during parsing.
    #
    # @api private
    # @return [String]
    FIELD_TYPE_ERROR = "Field must be a String or nil"

    # The comma character that separates language-range entries in the
    # Accept-Language header field value.
    #
    # @api private
    # @return [String] ","
    SEPARATOR = ","

    # The space character, stripped during parsing as whitespace around
    # separators is optional per RFC 2616.
    #
    # @api private
    # @return [String] " "
    SPACE = " "

    # The suffix that precedes quality values in language-range entries.
    # A language entry with a quality value has the form: +langtag;q=qvalue+
    #
    # @api private
    # @return [String] ";q="
    SUFFIX = ";q="

    # Regular expression pattern for validating quality values.
    #
    # Implements RFC 2616 Section 3.9 qvalue syntax:
    #
    #   qvalue = ( "0" [ "." 0*3DIGIT ] ) | ( "1" [ "." 0*3("0") ] )
    #
    # This pattern accepts:
    # - +0+ or +1+ (integer form)
    # - +0.+ followed by 1-3 digits (e.g., +0.5+, +0.75+, +0.123+)
    # - +1.+ followed by 1-3 zeros (e.g., +1.0+, +1.00+, +1.000+)
    #
    # @api private
    # @return [Regexp]
    #
    # @example Valid matches
    #   QVALUE_PATTERN.match?("0")     # => true
    #   QVALUE_PATTERN.match?("0.5")   # => true
    #   QVALUE_PATTERN.match?("0.123") # => true
    #   QVALUE_PATTERN.match?("1")     # => true
    #   QVALUE_PATTERN.match?("1.0")   # => true
    #   QVALUE_PATTERN.match?("1.000") # => true
    #
    # @example Invalid (no match)
    #   QVALUE_PATTERN.match?("0.1234") # => false (too many decimals)
    #   QVALUE_PATTERN.match?("1.5")    # => false (> 1)
    #   QVALUE_PATTERN.match?("2")      # => false (> 1)
    #   QVALUE_PATTERN.match?(".5")     # => false (missing leading digit)
    #   QVALUE_PATTERN.match?("1.001")  # => false (1.x must be zeros only)
    QVALUE_PATTERN = /\A(?:0(?:\.[0-9]{1,3})?|1(?:\.0{1,3})?)\z/

    # Regular expression pattern for validating language tags.
    #
    # Supports BCP 47 (RFC 5646) language tags, which supersede the RFC 1766
    # tags referenced in RFC 2616 Section 3.10.
    #
    # == Pattern Structure
    #
    # The pattern accepts either:
    # - The wildcard character +*+
    # - A primary subtag (1-8 ALPHA) followed by zero or more subtags
    #   (each 1-8 ALPHANUM, preceded by a hyphen)
    #
    # == BCP 47 vs RFC 1766
    #
    # RFC 2616 Section 3.10 references RFC 1766, which only allowed alphabetic
    # characters in subtags. However, BCP 47 (the current standard) permits
    # alphanumeric subtags to support:
    #
    # - Year-based variant subtags (e.g., +1996+ in +de-CH-1996+)
    # - Numeric region codes (e.g., +419+ for Latin America)
    # - Script subtags with numbers (rare but valid)
    #
    # This implementation follows BCP 47 for maximum compatibility with
    # modern language tags.
    #
    # @api private
    # @return [Regexp]
    #
    # @example Valid language tags
    #   LANGTAG_PATTERN.match?("en")         # => true
    #   LANGTAG_PATTERN.match?("en-US")      # => true
    #   LANGTAG_PATTERN.match?("zh-Hant-TW") # => true
    #   LANGTAG_PATTERN.match?("de-CH-1996") # => true
    #   LANGTAG_PATTERN.match?("*")          # => true
    #
    # @example Invalid language tags
    #   LANGTAG_PATTERN.match?("")              # => false (empty)
    #   LANGTAG_PATTERN.match?("toolongprimary") # => false (> 8 chars)
    #   LANGTAG_PATTERN.match?("en_US")         # => false (underscore)
    #   LANGTAG_PATTERN.match?("123")           # => false (numeric primary)
    LANGTAG_PATTERN = /\A(?:\*|[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*)\z/

    # The parsed language preferences extracted from the Accept-Language header.
    #
    # This hash maps downcased language tags to their quality values (scaled
    # to integers 0-1000). Tags are stored in lowercase for case-insensitive
    # matching.
    #
    # @api private
    # @return [Hash{String => Integer}] language tags mapped to quality values
    #
    # @example
    #   parser = Parser.new("en-GB;q=0.8, fr;q=0.9, de")
    #   parser.languages_range
    #   # => {"en-gb"=>800, "fr"=>900, "de"=>1000}
    attr_reader :languages_range

    # Creates a new Parser instance by parsing the given Accept-Language
    # header field value.
    #
    # The parser extracts all valid language-range entries from the header,
    # validates their language tags and quality values, and stores them for
    # subsequent matching operations.
    #
    # == Parsing Process
    #
    # 1. Validate that input is a String or nil
    # 2. Convert nil to empty string
    # 3. Normalize to lowercase for case-insensitive matching
    # 4. Remove all spaces (whitespace is insignificant per RFC 2616)
    # 5. Split on commas to get individual entries
    # 6. For each entry:
    #    a. Split on +;q=+ to separate tag from quality
    #    b. Validate the language tag
    #    c. Validate and parse the quality value (default 1.0 if absent)
    #    d. Store valid entries in the languages_range hash
    #
    # @param field [String, nil] the Accept-Language header field value.
    #   Common sources include +request.env["HTTP_ACCEPT_LANGUAGE"]+ in Rack
    #   applications or +request.headers["Accept-Language"]+ in Rails.
    #   When +nil+ is passed (header absent), it is treated as an empty string.
    #
    # @raise [TypeError] if +field+ is neither a String nor nil
    #
    # @example Standard header
    #   Parser.new("en-US, en;q=0.9, fr;q=0.8")
    #
    # @example With wildcard
    #   Parser.new("fr-FR, fr;q=0.9, *;q=0.5")
    #
    # @example With exclusion
    #   Parser.new("*, en;q=0")
    #
    # @example Empty or nil input
    #   Parser.new("")   # languages_range => {}
    #   Parser.new(nil)  # languages_range => {}
    #
    # @example Malformed input (invalid entries skipped)
    #   Parser.new("en, invalid;;q=0.5, fr;q=0.8")
    #   # languages_range => {"en"=>1000, "fr"=>800}
    #
    # @see #languages_range
    def initialize(field)
      raise ::TypeError, FIELD_TYPE_ERROR unless field.nil? || field.is_a?(::String)

      @languages_range = import(field)
    end

    # Finds the best matching language from the available options based on
    # the user's preferences expressed in the Accept-Language header.
    #
    # This method delegates to {Matcher} to perform the actual matching,
    # which considers:
    #
    # 1. **Quality values**: Higher q-values indicate stronger preference
    # 2. **Declaration order**: When q-values are equal, earlier declaration wins
    # 3. **Prefix matching**: +en+ matches +en-US+, +en-GB+, etc.
    # 4. **Wildcards**: +*+ matches any language not explicitly listed
    # 5. **Exclusions**: +q=0+ explicitly excludes a language
    #
    # == Matching Algorithm
    #
    # 1. Remove any available languages that are explicitly excluded (+q=0+)
    # 2. Iterate through preferred languages in descending quality order
    # 3. For each preferred language, find the first available language that:
    #    - Exactly matches the preferred tag, OR
    #    - Has the preferred tag as a prefix (followed by a hyphen)
    # 4. For wildcards, match any available language not already matched
    # 5. Return the first match found, or +nil+ if no match exists
    #
    # == Return Value Preservation
    #
    # The method returns the language tag exactly as provided in the
    # +available_langtags+ argument, preserving the original case. This is
    # important for direct use with +I18n.locale+ and similar APIs.
    #
    # @param available_langtags [Array<Symbol>] the languages your
    #   application supports. These are typically your +I18n.available_locales+
    #   or a similar list.
    #
    # @return [Symbol, nil] the best matching language tag from the
    #   available options, in its original form as passed to this method.
    #   Returns +nil+ if no acceptable match is found.
    #
    # @raise [TypeError] if any element in +available_langtags+ is not a Symbol
    #
    # @example Basic matching
    #   parser = Parser.new("da, en-GB;q=0.8, en;q=0.7")
    #   parser.match(:en, :da)
    #   # => :da
    #
    # @example Regional variant matching
    #   parser = Parser.new("en-GB, en;q=0.9")
    #   parser.match(:en, :"en-GB", :"en-US")
    #   # => :"en-GB"
    #
    # @example Prefix matching
    #   parser = Parser.new("en")
    #   parser.match(:"en-US", :"en-GB")
    #   # => :"en-US"  (first match wins)
    #
    # @example No match found
    #   parser = Parser.new("ja, zh")
    #   parser.match(:en, :fr, :de)
    #   # => nil
    #
    # @example Wildcard matching
    #   parser = Parser.new("en, *;q=0.5")
    #   parser.match(:fr)
    #   # => :fr  (matched by wildcard)
    #
    # @example Exclusion
    #   parser = Parser.new("*, en;q=0")
    #   parser.match(:en, :fr)
    #   # => :fr  (en is excluded)
    #
    # @example With I18n
    #   parser = Parser.new(request.env["HTTP_ACCEPT_LANGUAGE"])
    #   locale = parser.match(*I18n.available_locales) || I18n.default_locale
    #   I18n.locale = locale
    #
    # @see Matcher
    # @see https://tools.ietf.org/html/rfc2616#section-14.4 RFC 2616 Section 14.4
    def match(*available_langtags)
      Matcher.new(**languages_range).call(*available_langtags)
    end

    private

    # Parses the Accept-Language header field value into a hash of language
    # tags and their quality values.
    #
    # @param field [String, nil] the raw header field value
    # @return [Hash{String => Integer}] downcased language tags mapped to
    #   quality values (0-1000)
    def import(field)
      "#{field}".downcase.delete(SPACE).split(SEPARATOR).each_with_object({}) do |lang, hash|
        tag, quality = lang.split(SUFFIX)
        next unless valid_tag?(tag)

        quality_value = parse_quality(quality)
        next if quality_value.nil?

        hash[tag] = quality_value
      end
    end

    # Parses and validates a quality value string.
    #
    # @param quality [String, nil] the quality value string (without the ";q=" prefix)
    # @return [Integer, nil] the quality value scaled to 0-1000, or nil if invalid
    def parse_quality(quality)
      return DEFAULT_QUALITY if quality.nil?
      return unless valid_quality?(quality)

      qvalue_to_integer(quality)
    end

    # Converts a validated qvalue string to an integer in the range 0-1000.
    #
    # The conversion algorithm:
    # 1. Remove the decimal point (if present)
    # 2. Pad with zeros on the right to 4 characters
    # 3. Convert to integer
    #
    # This effectively multiplies the decimal value by 1000, avoiding
    # floating-point arithmetic entirely.
    #
    # @param quality [String] a validated qvalue string (e.g., "1", "0.8", "0.123")
    # @return [Integer] the quality value scaled to 0-1000
    #
    # @example Conversion examples
    #   qvalue_to_integer("1")     # => 1000  ("1" -> "1000" -> 1000)
    #   qvalue_to_integer("1.0")   # => 1000  ("10" -> "1000" -> 1000)
    #   qvalue_to_integer("0.8")   # => 800   ("08" -> "0800" -> 800)
    #   qvalue_to_integer("0.85")  # => 850   ("085" -> "0850" -> 850)
    #   qvalue_to_integer("0.123") # => 123   ("0123" -> "0123" -> 123)
    #   qvalue_to_integer("0")     # => 0     ("0" -> "0000" -> 0)
    def qvalue_to_integer(quality)
      quality.delete(DOT).ljust(4, DIGIT_ZERO).to_i
    end

    # Validates a quality value string against RFC 2616 Section 3.9.
    #
    # @param quality [String] the quality value to validate
    # @return [Boolean] true if the quality value is valid
    def valid_quality?(quality)
      quality.match?(QVALUE_PATTERN)
    end

    # Validates a language tag against BCP 47.
    #
    # @param tag [String, nil] the language tag to validate
    # @return [Boolean] true if the tag is valid (including wildcard)
    def valid_tag?(tag)
      return false if tag.nil?

      tag.match?(LANGTAG_PATTERN)
    end
  end
end

require_relative "matcher"
