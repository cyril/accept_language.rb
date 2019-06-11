# frozen_string_literal: true

module AcceptLanguage
  # @example
  #   Intersection.new('da, en-gb;q=0.8, en;q=0.7', :ar, :ja, :ro).call
  # @note Compare an Accept-Language header value with your application's
  #   supported languages to find the common languages that could be presented
  #   to a user.
  # @see https://tools.ietf.org/html/rfc2616#section-14.4
  class Intersection
    attr_reader :accepted_languages, :default_supported_language, :other_supported_languages

    def initialize(accepted_languages, default_supported_language, *other_supported_languages, truncate: true)
      @accepted_languages         = Parser.new(accepted_languages).call
      @default_supported_language = default_supported_language.to_sym
      @other_supported_languages  = other_supported_languages.map(&:to_sym).to_set

      return unless truncate

      @accepted_languages = @accepted_languages.map do |accepted_language|
        accepted_language[0, 2].to_sym
      end

      @default_supported_language = @default_supported_language[0, 2].to_sym

      @other_supported_languages = @other_supported_languages.map do |other_supported_language|
        other_supported_language[0, 2].to_sym
      end.to_set
    end

    def call
      accepted_languages.find do |accepted_language|
        break default_supported_language if accepted_language.equal?(wildcard)

        supported_languages.include?(accepted_language)
      end
    end

    protected

    def supported_languages
      other_supported_languages + Set[default_supported_language]
    end

    def wildcard
      :*
    end
  end
end

require_relative 'parser'
require 'set'
