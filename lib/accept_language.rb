# frozen_string_literal: true

# = Accept-Language Header Parser
#
# AcceptLanguage is a lightweight, thread-safe Ruby library for parsing the
# +Accept-Language+ HTTP header field as defined in RFC 7231 Section 5.3.5,
# with full support for BCP 47 language tags.
#
# == Purpose
#
# The +Accept-Language+ request header field is sent by user agents to indicate
# the set of natural languages that are preferred in the response. This library
# parses that header and matches the user's language preferences against your
# application's available languages, respecting quality values, wildcards,
# exclusions, and the Basic Filtering matching scheme defined in RFC 4647.
#
# == Standards Compliance
#
# This implementation conforms to:
#
# - {RFC 7231 Section 5.3.5}[https://www.rfc-editor.org/rfc/rfc7231#section-5.3.5] -
#   Accept-Language header field definition
# - {RFC 7231 Section 5.3.1}[https://www.rfc-editor.org/rfc/rfc7231#section-5.3.1] -
#   Quality values (qvalues) syntax
# - {RFC 4647 Section 2.1}[https://www.rfc-editor.org/rfc/rfc4647#section-2.1] -
#   Basic Language Range syntax
# - {RFC 4647 Section 3.3.1}[https://www.rfc-editor.org/rfc/rfc4647#section-3.3.1] -
#   Basic Filtering matching scheme
# - {BCP 47}[https://www.rfc-editor.org/info/bcp47] -
#   Tags for Identifying Languages
#
# Note: RFC 7231 obsoletes RFC 2616 (the original HTTP/1.1 specification).
# The +Accept-Language+ header behavior remains unchanged, ensuring full
# backward compatibility.
#
# == Basic Usage
#
#   require "accept_language"
#
#   # Parse an Accept-Language header and find the best match
#   AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:en, :da)
#   # => :da
#
#   # With regional variants
#   AcceptLanguage.parse("fr-CH, fr;q=0.9").match(:fr, :"fr-CH")
#   # => :"fr-CH"
#
#   # When no match is found
#   AcceptLanguage.parse("ja, zh;q=0.9").match(:en, :fr)
#   # => nil
#
# == Quality Values
#
# Quality values (q-values) indicate relative preference, ranging from +0+
# (not acceptable) to +1+ (most preferred). When omitted, the default
# quality value is +1+.
#
# Per RFC 7231 Section 5.3.1, valid q-values have at most three decimal places.
# Invalid q-values cause the associated language range to be ignored.
#
#   parser = AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")
#
#   parser.match(:en, :da)      # => :da       (q=1 beats q=0.8)
#   parser.match(:en, :"en-GB") # => :"en-GB"  (q=0.8 beats q=0.7)
#
# == Basic Filtering
#
# This library implements the Basic Filtering matching scheme defined in
# RFC 4647 Section 3.3.1. A language range matches a language tag if, in a
# case-insensitive comparison, it exactly equals the tag, or if it exactly
# equals a prefix of the tag such that the first character following the
# prefix is a hyphen (+"-"+).
#
#   # "zh" matches "zh-TW" (prefix match)
#   AcceptLanguage.parse("zh").match(:"zh-TW")
#   # => :"zh-TW"
#
#   # "zh-TW" does NOT match "zh" (more specific cannot match less specific)
#   AcceptLanguage.parse("zh-TW").match(:zh)
#   # => nil
#
#   # Prefix matching respects hyphen boundaries
#   AcceptLanguage.parse("zh").match(:zhx)
#   # => nil  (zhx is a different language code, not a subtag of zh)
#
# == Wildcards
#
# The wildcard character +*+ matches any language not explicitly matched by
# another language range in the header. This behavior is specific to HTTP,
# as noted in RFC 4647 Section 3.3.1.
#
#   # Wildcard matches any language
#   AcceptLanguage.parse("de, *;q=0.5").match(:ja)
#   # => :ja
#
#   # Explicit matches take precedence over wildcard
#   AcceptLanguage.parse("de, *;q=0.5").match(:de, :ja)
#   # => :de
#
# == Exclusions
#
# A quality value of +0+ explicitly marks a language as not acceptable:
#
#   # English is excluded despite wildcard
#   AcceptLanguage.parse("*, en;q=0").match(:en)
#   # => nil
#
#   AcceptLanguage.parse("*, en;q=0").match(:ja)
#   # => :ja
#
#   # Exclusions apply via prefix matching
#   AcceptLanguage.parse("*, en;q=0").match(:"en-GB")
#   # => nil  (en-GB is excluded via the "en" prefix)
#
# == Priority with Equal Quality Values
#
# When multiple languages share the same quality value, declaration order in
# the original header determines priority—the first declared language wins:
#
#   AcceptLanguage.parse("en;q=0.8, fr;q=0.8").match(:en, :fr)
#   # => :en  (declared first)
#
#   AcceptLanguage.parse("fr;q=0.8, en;q=0.8").match(:en, :fr)
#   # => :fr  (declared first)
#
# == Case Insensitivity
#
# Language tag matching is case-insensitive per RFC 4647 Section 2, but the
# original case of available language tags provided to +match+ is preserved
# in the return value:
#
#   AcceptLanguage.parse("EN-GB").match(:"en-gb")
#   # => :"en-gb"
#
#   AcceptLanguage.parse("en-gb").match(:"EN-GB")
#   # => :"EN-GB"
#
# == BCP 47 Language Tags
#
# Full support for BCP 47 language tags including script subtags, region
# subtags, and variant subtags:
#
#   # Script subtags (e.g., Hant for Traditional Chinese)
#   AcceptLanguage.parse("zh-Hant").match(:"zh-Hant-TW", :"zh-Hans-CN")
#   # => :"zh-Hant-TW"
#
#   # Variant subtags (e.g., 1996 for German orthography reform)
#   AcceptLanguage.parse("de-1996, de;q=0.9").match(:"de-CH-1996", :"de-CH")
#   # => :"de-CH-1996"
#
# == Thread Safety
#
# All AcceptLanguage operations are thread-safe. Parser instances are
# immutable after initialization and can be safely shared between threads.
#
# == Rack Integration Example
#
#   class LocaleMiddleware
#     def initialize(app, available_locales:, default_locale:)
#       @app = app
#       @available_locales = available_locales
#       @default_locale = default_locale
#     end
#
#     def call(env)
#       locale = detect_locale(env) || @default_locale
#       env["rack.locale"] = locale
#       @app.call(env)
#     end
#
#     private
#
#     def detect_locale(env)
#       header = env["HTTP_ACCEPT_LANGUAGE"]
#       return unless header
#
#       AcceptLanguage.parse(header).match(*@available_locales)
#     end
#   end
#
# == Rails Integration Example
#
#   class ApplicationController < ActionController::Base
#     before_action :set_locale
#
#     private
#
#     def set_locale
#       I18n.locale = preferred_locale || I18n.default_locale
#     end
#
#     def preferred_locale
#       header = request.headers["HTTP_ACCEPT_LANGUAGE"]
#       return unless header
#
#       AcceptLanguage.parse(header).match(*I18n.available_locales)
#     end
#   end
#
# @see Parser
# @see https://www.rfc-editor.org/rfc/rfc7231#section-5.3.5 RFC 7231 Section 5.3.5 — Accept-Language
# @see https://www.rfc-editor.org/rfc/rfc4647#section-3.3.1 RFC 4647 Section 3.3.1 — Basic Filtering
# @see https://www.rfc-editor.org/info/bcp47 BCP 47 — Tags for Identifying Languages
# @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language MDN Accept-Language
#
# @author Cyril Kato
# @since 1.0.0
module AcceptLanguage
  # Parses an +Accept-Language+ header field value and returns a parser
  # instance that can be used to match against available languages.
  #
  # The parser handles all aspects of the Accept-Language specification:
  # - Quality values (+q=0+ to +q=1+, default +1+ when omitted)
  # - Language range validation per RFC 4647 Section 2.1
  # - Wildcards (+*+)
  # - Case normalization (matching is case-insensitive)
  #
  # Invalid language ranges or malformed quality values in the input are
  # silently ignored, allowing the parser to handle real-world headers
  # that may not strictly conform to specifications.
  #
  # @param field [String, nil] the Accept-Language header field value.
  #   Typically obtained from +request.headers["HTTP_ACCEPT_LANGUAGE"]+ in
  #   Rails or +env["HTTP_ACCEPT_LANGUAGE"]+ in Rack applications.
  #   When +nil+ is passed (header absent), it is treated as an empty string,
  #   resulting in a parser that matches no languages.
  #
  # @return [Parser] a parser instance configured with the language preferences
  #   from the header. Call {Parser#match} on this instance to find the best
  #   matching language from your available options.
  #
  # @raise [TypeError] if +field+ is neither a String nor +nil+
  #
  # @example Basic parsing and matching
  #   parser = AcceptLanguage.parse("en-GB, en;q=0.9, fr;q=0.8")
  #   parser.match(:en, :"en-GB", :fr)
  #   # => :"en-GB"
  #
  # @example Handling missing or empty headers
  #   AcceptLanguage.parse("").match(:en, :fr)
  #   # => nil
  #
  #   AcceptLanguage.parse(nil).match(:en, :fr)
  #   # => nil
  #
  # @example Reusing a parser instance
  #   # Parse once, match multiple times
  #   user_prefs = AcceptLanguage.parse(header_value)
  #
  #   # Match for UI language
  #   ui_locale = user_prefs.match(*available_ui_locales)
  #
  #   # Match for content language
  #   content_locale = user_prefs.match(*available_content_locales)
  #
  # @example Handling edge cases
  #   # Invalid q-values are ignored
  #   AcceptLanguage.parse("en;q=2.0, fr;q=0.8").match(:en, :fr)
  #   # => :fr  (en is ignored due to invalid q-value > 1)
  #
  #   # Invalid language ranges are ignored
  #   AcceptLanguage.parse("123invalid, fr;q=0.8").match(:fr)
  #   # => :fr
  #
  # @see Parser#match
  # @see https://www.rfc-editor.org/rfc/rfc7231#section-5.3.5 RFC 7231 Section 5.3.5
  # @see https://www.rfc-editor.org/rfc/rfc4647#section-3.3.1 RFC 4647 Section 3.3.1
  def self.parse(field)
    Parser.new(field)
  end
end

require_relative File.join("accept_language", "parser")
