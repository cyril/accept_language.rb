# frozen_string_literal: true

require_relative File.join("..", "spec_helper")

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

      context "when input has malformed tags" do
        let(:raw_input) { ";q=0.8, fr;q=0.7, ;q=0.6, en-US" }

        it "ignores malformed tags" do
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

        context "with shorthand notation (RFC 2616 non-compliant)" do
          let(:raw_input) { "en-US;q=.8, fr;q=.123, de;q=1" }

          it "rejects shorthand notation per RFC 2616 Section 3.9" do
            # RFC 2616 requires: qvalue = ("0" ["." 0*3DIGIT]) | ("1" ["." 0*3("0")])
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
      end
    end

    context "with wildcards" do
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
    end

    context "with regex special characters" do
      context "when input contains dot star pattern" do
        let(:raw_input) { ".*" }

        it "rejects the malformed tag" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains dot" do
        let(:raw_input) { "en.US" }

        it "rejects the malformed tag" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains capturing group" do
        let(:raw_input) { "(en)" }

        it "rejects the malformed tag" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains character class" do
        let(:raw_input) { "[a-z]" }

        it "rejects the malformed tag" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains alternation" do
        let(:raw_input) { "en|fr" }

        it "rejects the malformed tag" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when input contains mixed valid and invalid tags" do
        let(:raw_input) { "en, .*;q=0.8, fr;q=0.7" }

        it "keeps only valid tags" do
          expect(parser.languages_range).to eq(
            "en" => 1000,
            "fr" => 700
          )
        end
      end
    end

    context "with BCP 47 language tags" do
      # BCP 47 (RFC 5646) extends RFC 1766 to allow alphanumeric subtags.
      # This is important for variant subtags and script codes.

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

      context "when using complex BCP 47 tags" do
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

      context "when subtag exceeds 8 characters" do
        let(:raw_input) { "en-verylongsubtag" }

        it "rejects subtags longer than 8 characters" do
          expect(parser.languages_range).to eq({})
        end
      end

      context "when primary tag contains digits" do
        let(:raw_input) { "e2-US" }

        it "rejects primary tags with digits (BCP 47 requires ALPHA only)" do
          expect(parser.languages_range).to eq({})
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

      context "when partial match is available" do
        context "with single option" do
          let(:available_langtags) { [:en] }

          it "returns the partial match" do
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
end
