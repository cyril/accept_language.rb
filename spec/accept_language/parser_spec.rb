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
            "en-US" => BigDecimal("0.8"),
            "fr"    => BigDecimal("0.7")
          )
        end
      end

      context "when input has malformed tags" do
        let(:raw_input) { ";q=0.8, fr;q=0.7, ;q=0.6, en-US" }

        it "ignores malformed tags" do
          expect(parser.languages_range).to eq(
            "fr"    => BigDecimal("0.7"),
            "en-US" => BigDecimal("1.0")
          )
        end
      end
    end

    context "with quality values" do
      context "when using valid quality values" do
        context "with short decimal notation" do
          let(:raw_input) { "en-US;q=.8, fr;q=.123, de;q=1" }

          it "accepts the short notation" do
            expect(parser.languages_range).to eq(
              "en-US" => BigDecimal("0.8"),
              "fr"    => BigDecimal("0.123"),
              "de"    => BigDecimal("1.0")
            )
          end
        end

        context "with full decimal notation" do
          let(:raw_input) { "en-US;q=0.8, fr;q=0.123, de;q=1.0" }

          it "accepts the full notation" do
            expect(parser.languages_range).to eq(
              "en-US" => BigDecimal("0.8"),
              "fr"    => BigDecimal("0.123"),
              "de"    => BigDecimal("1.0")
            )
          end
        end

        context "with implicit quality value (no q parameter)" do
          let(:raw_input) { "en-US, fr;q=0.8" }

          it "assigns default quality value of 1.0" do
            expect(parser.languages_range).to eq(
              "en-US" => BigDecimal("1.0"),
              "fr"    => BigDecimal("0.8")
            )
          end
        end

        context "with zero quality value" do
          let(:raw_input) { "en-US;q=0.8, fr;q=0, de;q=0.7" }

          it "includes zero quality entries" do
            expect(parser.languages_range).to eq(
              "en-US" => BigDecimal("0.8"),
              "fr"    => BigDecimal("0.0"),
              "de"    => BigDecimal("0.7")
            )
          end
        end

        context "with multiple zero quality values" do
          let(:raw_input) { "en-US;q=0.8, fr;q=0, de;q=0, it;q=0.7" }

          it "includes all zero quality entries" do
            expect(parser.languages_range).to eq(
              "en-US" => BigDecimal("0.8"),
              "fr"    => BigDecimal("0.0"),
              "de"    => BigDecimal("0.0"),
              "it"    => BigDecimal("0.7")
            )
          end
        end
      end

      context "when using invalid quality values" do
        context "with value greater than 1" do
          let(:raw_input) { "en-US;q=1.1, fr;q=0.8" }

          it "ignores the invalid entry" do
            expect(parser.languages_range).to eq(
              "fr" => BigDecimal("0.8")
            )
          end
        end

        context "with too many decimal places" do
          let(:raw_input) { "en-US;q=0.8888, fr;q=0.8" }

          it "ignores the invalid entry" do
            expect(parser.languages_range).to eq(
              "fr" => BigDecimal("0.8")
            )
          end
        end

        context "with negative value" do
          let(:raw_input) { "en-US;q=-0.8, fr;q=0.8" }

          it "ignores the invalid entry" do
            expect(parser.languages_range).to eq(
              "fr" => BigDecimal("0.8")
            )
          end
        end

        context "with malformed format" do
          let(:raw_input) { "en-US;q=1., fr;q=0.8, de;q=01.0" }

          it "ignores all invalid entries" do
            expect(parser.languages_range).to eq(
              "fr" => BigDecimal("0.8")
            )
          end
        end

        context "with mix of valid and invalid values" do
          let(:raw_input) { "da;q=1.0, en-GB;q=1.5, en;q=.7, fr;q=0.8888, de;q=0.9" }

          it "keeps only valid entries" do
            expect(parser.languages_range).to eq(
              "da" => BigDecimal("1.0"),
              "en" => BigDecimal("0.7"),
              "de" => BigDecimal("0.9")
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
            "fr"    => BigDecimal("1.0"),
            "fr-CH" => BigDecimal("0.9"),
            "en"    => BigDecimal("0.8"),
            "de"    => BigDecimal("0.7"),
            "*"     => BigDecimal("0.5")
          )
        end
      end

      context "when using only wildcard" do
        let(:raw_input) { "*" }

        it "treats wildcard with default quality" do
          expect(parser.languages_range).to eq(
            "*" => BigDecimal("1.0")
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
