# frozen_string_literal: true

require_relative "spec_helper"

# Integration tests for the AcceptLanguage module.
#
# These tests verify the complete parsing and matching flow as defined in:
# - RFC 7231 Section 5.3.5 (Accept-Language header)
# - RFC 7231 Section 5.3.1 (Quality values)
# - RFC 4647 Section 3.3.1 (Basic Filtering)
#
# @see https://www.rfc-editor.org/rfc/rfc7231#section-5.3.5
# @see https://www.rfc-editor.org/rfc/rfc4647#section-3.3.1
RSpec.describe AcceptLanguage do
  describe ".parse" do
    subject { described_class.parse(field) }

    context "with a valid Accept-Language header value" do
      let(:field) { "da, en-GB;q=0.8, en;q=0.7" }

      it "returns an instance of Parser" do
        expect(subject).to be_an_instance_of(AcceptLanguage::Parser)
      end

      it "returns a parser that can match languages" do
        expect(subject.match(:da, :en)).to be :da
      end
    end

    context "with nil (absent header)" do
      let(:field) { nil }

      it "returns an instance of Parser" do
        expect(subject).to be_an_instance_of(AcceptLanguage::Parser)
      end

      it "returns a parser with empty languages_range" do
        expect(subject.languages_range).to eq({})
      end

      it "returns nil when matching" do
        expect(subject.match(:en, :fr)).to be_nil
      end
    end

    context "with empty string" do
      let(:field) { "" }

      it "returns an instance of Parser" do
        expect(subject).to be_an_instance_of(AcceptLanguage::Parser)
      end

      it "returns nil when matching" do
        expect(subject.match(:en, :fr)).to be_nil
      end
    end
  end

  describe "integration: parse and match" do
    # These tests demonstrate the complete workflow from parsing an
    # Accept-Language header to finding the best matching language.

    context "with RFC 7231 Section 5.3.5 example" do
      # Example from the specification:
      # "da, en-gb;q=0.8, en;q=0.7"
      # This means: "I prefer Danish, but will accept British English
      # and other types of English."

      let(:parser) { described_class.parse("da, en-gb;q=0.8, en;q=0.7") }

      it "prefers Danish when available" do
        expect(parser.match(:da, :en, :"en-GB")).to be :da
      end

      it "falls back to British English when Danish is unavailable" do
        expect(parser.match(:en, :"en-GB")).to be :"en-GB"
      end

      it "falls back to English when neither Danish nor British English is available" do
        expect(parser.match(:en, :fr)).to be :en
      end

      it "returns nil when no preferred language is available" do
        expect(parser.match(:fr, :de)).to be_nil
      end
    end

    context "with wildcard and exclusion" do
      # "*, en;q=0" means "any language except English"

      let(:parser) { described_class.parse("*, en;q=0") }

      it "accepts any language except English" do
        expect(parser.match(:fr)).to be :fr
      end

      it "rejects English" do
        expect(parser.match(:en)).to be_nil
      end

      it "rejects English variants via prefix matching" do
        expect(parser.match(:"en-US", :"en-GB")).to be_nil
      end

      it "prefers non-English when both are available" do
        expect(parser.match(:en, :fr, :de)).to be :fr
      end
    end

    context "with script subtags" do
      # Chinese with script subtags for Traditional vs Simplified

      let(:parser) { described_class.parse("zh-Hant, zh-Hans;q=0.9, zh;q=0.8") }

      it "prefers Traditional Chinese" do
        expect(parser.match(:"zh-Hant-TW", :"zh-Hans-CN")).to be :"zh-Hant-TW"
      end

      it "falls back to Simplified Chinese" do
        expect(parser.match(:"zh-Hans-CN", :zh)).to be :"zh-Hans-CN"
      end

      it "falls back to generic Chinese" do
        expect(parser.match(:zh, :en)).to be :zh
      end
    end

    context "with variant subtags" do
      # German orthography variants

      let(:parser) { described_class.parse("de-1996, de;q=0.9") }

      it "prefers 1996 orthography" do
        expect(parser.match(:"de-CH-1996", :"de-CH")).to be :"de-CH-1996"
      end

      it "falls back to generic German" do
        expect(parser.match(:"de-AT", :"de-CH")).to be :"de-AT"
      end
    end

    context "with quality value ordering" do
      let(:parser) { described_class.parse("fr;q=0.7, en;q=0.8, de;q=0.9") }

      it "respects quality value ordering" do
        expect(parser.match(:fr, :en, :de)).to be :de
      end
    end

    context "with declaration order tie-breaking" do
      # When quality values are equal, declaration order wins

      let(:parser) { described_class.parse("en;q=0.8, fr;q=0.8, de;q=0.8") }

      it "prefers first declared language when qualities are equal" do
        expect(parser.match(:de, :fr, :en)).to be :en
      end
    end

    context "with case-insensitive matching" do
      let(:parser) { described_class.parse("EN-US") }

      it "matches regardless of case" do
        expect(parser.match(:"en-us")).to be :"en-us"
      end

      it "preserves the case of available language tags" do
        expect(parser.match(:"en-US")).to be :"en-US"
      end
    end

    context "with prefix matching" do
      # RFC 4647 Section 3.3.1: A language range matches if it exactly
      # equals the tag, or if it exactly equals a prefix of the tag
      # such that the first character following the prefix is "-".

      let(:parser) { described_class.parse("en") }

      it "matches exact tag" do
        expect(parser.match(:en)).to be :en
      end

      it "matches via prefix" do
        expect(parser.match(:"en-US")).to be :"en-US"
      end

      it "does not match different language with similar prefix" do
        expect(parser.match(:eng)).to be_nil
      end
    end

    context "with real-world browser headers" do
      context "with Chrome on macOS (US)" do
        let(:parser) { described_class.parse("en-US,en;q=0.9") }

        it "matches American English" do
          expect(parser.match(:"en-US", :"en-GB", :en)).to be :"en-US"
        end
      end

      context "with Firefox with multiple languages" do
        let(:parser) { described_class.parse("fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7") }

        it "prefers French (France)" do
          expect(parser.match(:en, :fr, :"fr-FR", :"en-US")).to be :"fr-FR"
        end

        it "falls back appropriately" do
          expect(parser.match(:en, :"en-US")).to be :"en-US"
        end
      end

      context "with Safari with Chinese variants" do
        let(:parser) { described_class.parse("zh-TW,zh-Hant;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6") }

        it "prefers Taiwan Chinese" do
          expect(parser.match(:"zh-TW", :"zh-CN", :en)).to be :"zh-TW"
        end

        it "falls back to Traditional Chinese" do
          expect(parser.match(:"zh-Hant-HK", :"zh-Hans-CN", :en)).to be :"zh-Hant-HK"
        end
      end
    end
  end
end
