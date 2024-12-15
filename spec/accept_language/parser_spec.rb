# frozen_string_literal: true

require_relative File.join("..", "spec_helper")

RSpec.describe AcceptLanguage::Parser do
  describe "#languages_range" do
    let(:parser) { described_class.new(raw_input) }

    context "with valid quality values" do
      context "when using short decimal notation" do
        let(:raw_input) { "en-US;q=.8, fr;q=.123, de;q=1" }

        it "accepts the short notation" do
          expect(parser.languages_range).to eq(
            "en-US" => BigDecimal("0.8"),
            "fr"    => BigDecimal("0.123"),
            "de"    => BigDecimal("1.0")
          )
        end
      end

      context "when using full decimal notation" do
        let(:raw_input) { "en-US;q=0.8, fr;q=0.123, de;q=1.0" }

        it "accepts the full notation" do
          expect(parser.languages_range).to eq(
            "en-US" => BigDecimal("0.8"),
            "fr"    => BigDecimal("0.123"),
            "de"    => BigDecimal("1.0")
          )
        end
      end
    end

    context "with invalid quality values" do
      context "when quality value is greater than 1" do
        let(:raw_input) { "en-US;q=1.1, fr;q=0.8" }

        it "ignores the invalid entry" do
          expect(parser.languages_range).to eq(
            "fr" => BigDecimal("0.8")
          )
        end
      end

      context "when quality value has too many decimal places" do
        let(:raw_input) { "en-US;q=0.8888, fr;q=0.8" }

        it "ignores the invalid entry" do
          expect(parser.languages_range).to eq(
            "fr" => BigDecimal("0.8")
          )
        end
      end

      context "when quality value is negative" do
        let(:raw_input) { "en-US;q=-0.8, fr;q=0.8" }

        it "ignores the invalid entry" do
          expect(parser.languages_range).to eq(
            "fr" => BigDecimal("0.8")
          )
        end
      end

      context "when quality value has invalid format" do
        let(:raw_input) { "en-US;q=1., fr;q=0.8, de;q=01.0" }

        it "ignores all invalid entries" do
          expect(parser.languages_range).to eq(
            "fr" => BigDecimal("0.8")
          )
        end
      end

      context "when mixing valid and invalid quality values" do
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

    context "without a wildcard" do
      let(:raw_input) { "da, en-GB;q=0.8, en;q=0.7" }

      it "returns languages range" do
        expect(parser.languages_range).to eq(
          "da"    => BigDecimal("1.0"),
          "en-GB" => BigDecimal("0.8"),
          "en"    => BigDecimal("0.7")
        )
      end

      describe "#match" do
        context "when English (United Kingdom) is available" do
          let(:available_langtags) { [:"en-GB"] }

          it { expect(parser.match(*available_langtags)).to be :"en-GB" }
        end

        context "when English is available" do
          let(:available_langtags) { [:en] }

          it { expect(parser.match(*available_langtags)).to be :en }

          context "when English (United Kingdom) is available" do
            let(:available_langtags) { %i[en en-GB] }

            it { expect(parser.match(*available_langtags)).to be :"en-GB" }
          end
        end

        context "when French is available" do
          let(:available_langtags) { [:fr] }

          it { expect(parser.match(*available_langtags)).to be_nil }
        end
      end
    end

    context "with a wildcard" do
      let(:raw_input) { "fr, fr-CH;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5" }

      it "returns languages range" do
        expect(parser.languages_range).to eq(
          "fr"    => BigDecimal("1.0"),
          "fr-CH" => BigDecimal("0.9"),
          "en"    => BigDecimal("0.8"),
          "de"    => BigDecimal("0.7"),
          "*"     => BigDecimal("0.5")
        )
      end

      describe "#match" do
        context "when English (United Kingdom) is available" do
          let(:available_langtags) { [:"en-GB"] }

          it { expect(parser.match(*available_langtags)).to be :"en-GB" }
        end

        context "when English is available" do
          let(:available_langtags) { [:en] }

          it { expect(parser.match(*available_langtags)).to be :en }

          context "when English (United Kingdom) is available" do
            let(:available_langtags) { %i[en en-GB] }

            it { expect(parser.match(*available_langtags)).to be :en }
          end
        end

        context "when French is available" do
          let(:available_langtags) { [:fr] }

          it { expect(parser.match(*available_langtags)).to be :fr }
        end
      end
    end
  end
end
