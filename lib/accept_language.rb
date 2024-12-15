# frozen_string_literal: true

# AcceptLanguage is a lightweight library that parses Accept-Language HTTP headers (RFC 2616) to determine
# user language preferences. It converts raw header values into a structured format for matching against
# your application's supported languages.
#
# @example
#   AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")
#   # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>1.0, "en-GB"=>0.8, "en"=>0.7}>
#
# @example Integration with Rails
#   class ApplicationController < ActionController::Base
#     before_action :set_locale
#
#     private
#
#     def set_locale
#       header = request.env["HTTP_ACCEPT_LANGUAGE"]
#       locale = AcceptLanguage.parse(header).match(*I18n.available_locales)
#       I18n.locale = locale || I18n.default_locale
#     end
#   end
#
# @see https://tools.ietf.org/html/rfc2616#section-14.4
module AcceptLanguage
  # Parses an Accept-Language header field value into a Parser object, which can then be used to match
  # user's preferred languages against the languages your application supports.
  # This method accepts a string argument in the format as described in RFC 2616 Section 14.4, and returns
  # a Parser object which responds to the #match method.
  #
  # @param field [String] the Accept-Language header field value.
  #
  # @example
  #   AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")
  #   # => #<AcceptLanguage::Parser:0x00007 @languages_range={"da"=>1.0, "en-GB"=>0.8, "en"=>0.7}>
  #
  # @return [Parser] a Parser object that responds to #match method.
  def self.parse(field)
    Parser.new(field)
  end
end

# Load the Parser class
require_relative File.join("accept_language", "parser")
