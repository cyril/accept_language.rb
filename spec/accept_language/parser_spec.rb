#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative File.join("..", "spec_helper")
require_relative File.join("..", "..", "lib", "accept_language", "parser")

# Tests for the Accept-Language header parser.
#
# @see https://www.rfc-editor.org/rfc/rfc7231#section-5.3.5
# @see https://www.rfc-editor.org/rfc/rfc7231#section-5.3.1
# @see https://www.rfc-editor.org/rfc/rfc4647#section-2.1
RSpec.describe AcceptLanguage::Parser do
  describe "#languages_range" do
    let(:parser) { described_class.new(raw_input) }

    context "with edge cases" do
      context "when input is nil" do
        let(:raw_input) { nil }

        it "returns empty hash" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input is empty" do
        let(:raw_input) { "" }

        it "returns empty hash" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input has excessive spaces" do
        let(:raw_input) { "  en-US  ;  q=0.8  ,  fr  ;  q=0.7  " }

        it "handles the spaces correctly" do
          expect(parser.languages_range).to eq(
            "en-us" => 800,
            "fr"    => 700
          )
        end
      end

      context "when input has malformed ranges" do
        let(:raw_input) { ";q=0.8, fr;q=0.7, ;q=0.6, en-US" }

        it "ignores malformed ranges" do
          expect(parser.languages_range).to eq(
            "fr"    => 700,
            "en-us" => 1000
          )
        end
      end

      context "when input has uppercase Q parameter" do
        let(:raw_input) { "en-US;Q=0.8, fr;Q=0.7" }

        it "handles uppercase Q correctly" do
          expect(parser.languages_range).to eq(
            "en-us" => 800,
            "fr"    => 700
          )
        end
      end
    end

    context "with quality values" do
      # RFC 7231 Section 5.3.1 defines the syntax for quality values:
      #   qvalue = ( "0" [ "." 0*3DIGIT ] ) / ( "1" [ "." 0*3("0") ] )

      context "when using valid quality values" do
        context "with full decimal notation" do
          let(:raw_input) { "en-US;q=0.8, fr;q=0.123, de;q=1.0" }

          it "accepts the full notation" do
            expect(parser.languages_range).to eq(
              "en-us" => 800,
              "fr"    => 123,
              "de"    => 1000
            )
          end
        end

        context "with implicit quality value (no q parameter)" do
          let(:raw_input) { "en-US, fr;q=0.8" }

          it "assigns default quality value of 1.0" do
            expect(parser.languages_range).to eq(
              "en-us" => 1000,
              "fr"    => 800
            )
          end
        end

        context "with zero quality value" do
          # RFC 7231 Section 5.3.1: "a value of 0 means 'not acceptable'"
          let(:raw_input) { "en-US;q=0.8, fr;q=0, de;q=0.7" }

          it "includes zero quality entries" do
            expect(parser.languages_range).to eq(
              "en-us" => 800,
              "fr"    => 0,
              "de"    => 700
            )
          end
        end

        context "with multiple zero quality values" do
          let(:raw_input) { "en-US;q=0.8, fr;q=0, de;q=0, it;q=0.7" }

          it "includes all zero quality entries" do
            expect(parser.languages_range).to eq(
              "en-us" => 800,
              "fr"    => 0,
              "de"    => 0,
              "it"    => 700
            )
          end
        end

        context "with boundary values" do
          let(:raw_input) { "en;q=0, fr;q=0.001, de;q=0.999, it;q=1, ja;q=1.000" }

          it "accepts all valid boundary values" do
            expect(parser.languages_range).to eq(
              "en" => 0,
              "fr" => 1,
              "de" => 999,
              "it" => 1000,
              "ja" => 1000
            )
          end
        end
      end

      context "when using invalid quality values" do
        context "with value greater than 1" do
          let(:raw_input) { "en-US;q=1.1, fr;q=0.8" }

          it "ignores the invalid entry" do
            expect(parser.languages_range).to eq(
              "fr" => 800
            )
          end
        end

        context "with too many decimal places" do
          # RFC 7231 Section 5.3.1: maximum of 3 decimal places
          let(:raw_input) { "en-US;q=0.8888, fr;q=0.8" }

          it "ignores the invalid entry" do
            expect(parser.languages_range).to eq(
              "fr" => 800
            )
          end
        end

        context "with negative value" do
          let(:raw_input) { "en-US;q=-0.8, fr;q=0.8" }

          it "ignores the invalid entry" do
            expect(parser.languages_range).to eq(
              "fr" => 800
            )
          end
        end

        context "with malformed format" do
          let(:raw_input) { "en-US;q=1., fr;q=0.8, de;q=01.0" }

          it "ignores all invalid entries" do
            expect(parser.languages_range).to eq(
              "fr" => 800
            )
          end
        end

        context "with shorthand notation (RFC 7231 non-compliant)" do
          let(:raw_input) { "en-US;q=.8, fr;q=.123, de;q=1" }

          it "rejects shorthand notation per RFC 7231 Section 5.3.1" do
            # RFC 7231 requires: qvalue = ("0" ["." 0*3DIGIT]) | ("1" ["." 0*3("0")])
            # Shorthand ".8" is not valid; must be "0.8"
            expect(parser.languages_range).to eq(
              "de" => 1000
            )
          end
        end

        context "with mix of valid and invalid values" do
          let(:raw_input) { "da;q=1.0, en-GB;q=1.5, en;q=.7, fr;q=0.8888, de;q=0.9" }

          it "keeps only valid entries" do
            # en-GB;q=1.5 invalid (>1), en;q=.7 invalid (shorthand), fr;q=0.8888 invalid (>3 decimals)
            expect(parser.languages_range).to eq(
              "da" => 1000,
              "de" => 900
            )
          end
        end

        context "with non-zero values after decimal for 1.x" do
          let(:raw_input) { "en;q=1.001, fr;q=1.1, de;q=0.8" }

          it "rejects 1.x values where x is not all zeros" do
            expect(parser.languages_range).to eq(
              "de" => 800
            )
          end
        end
      end
    end

    context "with wildcards" do
      # RFC 4647 Section 2.1: The wildcard "*" is a valid basic language range

      context "when using wildcard with regular entries" do
        let(:raw_input) { "fr, fr-CH;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5" }

        it "processes the wildcard correctly" do
          expect(parser.languages_range).to eq(
            "fr"    => 1000,
            "fr-ch" => 900,
            "en"    => 800,
            "de"    => 700,
            "*"     => 500
          )
        end
      end

      context "when using only wildcard" do
        let(:raw_input) { "*" }

        it "treats wildcard with default quality" do
          expect(parser.languages_range).to eq(
            "*" => 1000
          )
        end
      end

      context "when wildcard has zero quality" do
        let(:raw_input) { "en, *;q=0" }

        it "includes wildcard with zero quality" do
          expect(parser.languages_range).to eq(
            "en" => 1000,
            "*"  => 0
          )
        end
      end
    end

    context "with regex special characters" do
      # These tests ensure the parser safely handles potentially malicious input

      context "when input contains dot star pattern" do
        let(:raw_input) { ".*" }

        it "rejects the malformed range" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains dot" do
        let(:raw_input) { "en.US" }

        it "rejects the malformed range" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains capturing group" do
        let(:raw_input) { "(en)" }

        it "rejects the malformed range" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains character class" do
        let(:raw_input) { "[a-z]" }

        it "rejects the malformed range" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains alternation" do
        let(:raw_input) { "en|fr" }

        it "rejects the malformed range" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains mixed valid and invalid ranges" do
        let(:raw_input) { "en, .*;q=0.8, fr;q=0.7" }

        it "keeps only valid ranges" do
          expect(parser.languages_range).to eq(
            "en" => 1000,
            "fr" => 700
          )
        end
      end
    end

    context "with RFC 4647 Section 2.1 Basic Language Range syntax" do
      # RFC 4647 Section 2.1 defines the syntax:
      #   language-range = (1*8ALPHA *("-" 1*8alphanum)) / "*"
      #   alphanum       = ALPHA / DIGIT
      #
      # This syntax is compatible with BCP 47 language tags.

      context "when using variant subtags with numbers" do
        let(:raw_input) { "de-CH-1996;q=0.9, de-CH;q=0.8" }

        it "accepts numeric variant subtags" do
          expect(parser.languages_range).to eq(
            "de-ch-1996" => 900,
            "de-ch"      => 800
          )
        end
      end

      context "when using script subtags" do
        let(:raw_input) { "zh-Hans-CN, zh-Hant-TW;q=0.9" }

        it "accepts 4-letter script subtags" do
          expect(parser.languages_range).to eq(
            "zh-hans-cn" => 1000,
            "zh-hant-tw" => 900
          )
        end
      end

      context "when using complex language ranges" do
        let(:raw_input) { "sl-IT-nedis;q=0.8, sl-nedis;q=0.7, sl;q=0.6" }

        it "accepts dialect variant subtags" do
          expect(parser.languages_range).to eq(
            "sl-it-nedis" => 800,
            "sl-nedis"    => 700,
            "sl"          => 600
          )
        end
      end

      context "when using registered variant with digits" do
        let(:raw_input) { "de-1996, de-1901;q=0.5" }

        it "accepts year-based variant subtags" do
          # 1996 = German orthography reform, 1901 = traditional orthography
          expect(parser.languages_range).to eq(
            "de-1996" => 1000,
            "de-1901" => 500
          )
        end
      end

      context "when using numeric region codes" do
        let(:raw_input) { "es-419;q=0.9, es;q=0.8" }

        it "accepts UN M.49 numeric region codes" do
          # 419 = Latin America and the Caribbean
          expect(parser.languages_range).to eq(
            "es-419" => 900,
            "es"     => 800
          )
        end
      end

      context "when subtag exceeds 8 characters" do
        let(:raw_input) { "en-verylongsubtag" }

        it "rejects subtags longer than 8 characters" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when primary subtag exceeds 8 characters" do
        let(:raw_input) { "verylongprimary-US" }

        it "rejects primary subtags longer than 8 characters" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when primary subtag contains digits" do
        let(:raw_input) { "e2-US" }

        it "rejects primary subtags with digits (must be ALPHA only)" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when primary subtag is numeric" do
        let(:raw_input) { "123-US" }

        it "rejects numeric primary subtags" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when subtag is empty" do
        let(:raw_input) { "en--US" }

        it "rejects empty subtags" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when using single character primary subtag" do
        let(:raw_input) { "a" }

        it "accepts single character primary subtag" do
          expect(parser.languages_range).to eq(
            "a" => 1000
          )
        end
      end

      context "when using 8 character primary subtag" do
        let(:raw_input) { "abcdefgh" }

        it "accepts 8 character primary subtag (maximum allowed)" do
          expect(parser.languages_range).to eq(
            "abcdefgh" => 1000
          )
        end
      end
    end
  end

  describe "#match" do
    let(:parser) { described_class.new(raw_input) }

    context "when matching without wildcards" do
      let(:raw_input) { "da, en-GB;q=0.8, en;q=0.7" }

      context "when exact match is available" do
        let(:available_langtags) { [:"en-GB"] }

        it "returns the exact match" do
          expect(parser.match(*available_langtags)).to be :"en-GB"
        end
      end

      context "when prefix match is available" do
        context "with single option" do
          let(:available_langtags) { [:en] }

          it "returns the prefix match" do
            expect(parser.match(*available_langtags)).to be :en
          end
        end

        context "with multiple options" do
          let(:available_langtags) { %i[en en-GB] }

          it "returns the best quality match" do
            expect(parser.match(*available_langtags)).to be :"en-GB"
          end
        end
      end

      context "when no match is available" do
        let(:available_langtags) { [:fr] }

        it "returns nil" do
          expect(parser.match(*available_langtags)).to be_nil
        end
      end
    end

    context "when matching with wildcards" do
      let(:raw_input) { "fr, fr-CH;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5" }

      context "when preferred language is available" do
        let(:available_langtags) { [:fr] }

        it "returns the preferred language" do
          expect(parser.match(*available_langtags)).to be :fr
        end
      end

      context "when only wildcard match is available" do
        let(:available_langtags) { [:ja] }

        it "returns the wildcard match" do
          expect(parser.match(*available_langtags)).to be :ja
        end
      end

      context "when both specific and wildcard matches are available" do
        let(:available_langtags) { %i[ja fr] }

        it "returns the specific match with higher quality" do
          expect(parser.match(*available_langtags)).to be :fr
        end
      end
    end
  end

  describe "input type validation" do
    context "when input is not a String or nil" do
      it "raises TypeError for Integer" do
        expect { described_class.new(42) }.to raise_exception(TypeError)
      end

      it "raises TypeError for Array" do
        expect { described_class.new(["en"]) }.to raise_exception(TypeError)
      end

      it "raises TypeError for Symbol" do
        expect { described_class.new(:en) }.to raise_exception(TypeError)
      end

      it "raises TypeError for Hash" do
        expect { described_class.new({ en: 1 }) }.to raise_exception(TypeError)
      end
    end

    context "when input is valid" do
      it "accepts String" do
        expect { described_class.new("en") }.not_to raise_exception(TypeError)
      end

      it "accepts nil" do
        expect { described_class.new(nil) }.not_to raise_exception(TypeError)
      end

      it "accepts empty String" do
        expect { described_class.new("") }.not_to raise_exception(TypeError)
      end
    end
  end
end
