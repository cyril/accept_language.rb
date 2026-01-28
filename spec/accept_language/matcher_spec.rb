#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative File.join("..", "spec_helper")
require_relative File.join("..", "..", "lib", "accept_language", "matcher")

# Tests for the Basic Filtering matching scheme defined in RFC 4647 Section 3.3.1.
#
# Note: The Matcher class expects a hash where:
# - Keys are downcased language range strings
# - Values are integers 0-1000 (quality values multiplied by 1000)
#
# @see https://www.rfc-editor.org/rfc/rfc4647#section-3.3.1
# @see https://www.rfc-editor.org/rfc/rfc7231#section-5.3.5
RSpec.describe AcceptLanguage::Matcher do
  let(:best_match) { matcher.call(*available_langtags) }

  describe "Type validation" do
    let(:matcher) { described_class.new("en" => 1000) }

    context "when passing a String instead of Symbol" do
      it "raises TypeError" do
        expect { matcher.call("en") }.to raise_exception(TypeError)
      end
    end

    context "when passing an Integer instead of Symbol" do
      it "raises TypeError" do
        expect { matcher.call(42) }.to raise_exception(TypeError)
      end
    end

    context "when passing nil instead of Symbol" do
      it "raises TypeError" do
        expect { matcher.call(nil) }.to raise_exception(TypeError)
      end
    end

    context "when passing mixed types including a non-Symbol" do
      it "raises TypeError" do
        expect { matcher.call(:en, "fr") }.to raise_exception(TypeError)
      end
    end

    context "when passing valid Symbols" do
      it "does not raise" do
        expect { matcher.call(:en, :fr) }.not_to raise_exception(TypeError)
      end
    end
  end

  context "when asking for Chinese (Taiwan)" do
    let(:available_langtags) { [available_langtag] }
    let(:matcher) { described_class.new("zh-tw" => 1000) }

    context "when Chinese is available" do
      let(:available_langtag) { :zh }

      it { expect(best_match).to be_nil }
    end

    context "when Chinese (Hong Kong) is available" do
      let(:available_langtag) { :"zh-HK" }

      it { expect(best_match).to be_nil }
    end

    context "when Chinese (Taiwan) is available" do
      let(:available_langtag) { :"zh-TW" }

      it { expect(best_match).to be :"zh-TW" }
    end

    context "when Uyghur (China) is available" do
      let(:available_langtag) { :"ug-CN" }

      it { expect(best_match).to be_nil }
    end
  end

  context "when asking for Chinese" do
    let(:available_langtags) { [available_langtag] }
    let(:matcher) { described_class.new("zh" => 1000) }

    context "when Chinese is available" do
      let(:available_langtag) { :zh }

      it { expect(best_match).to be :zh }
    end

    context "when Chinese (Hong Kong) is available" do
      let(:available_langtag) { :"zh-HK" }

      it { expect(best_match).to be :"zh-HK" }
    end

    context "when Chinese (Taiwan) is available" do
      let(:available_langtag) { :"zh-TW" }

      it { expect(best_match).to be :"zh-TW" }
    end

    context "when Uyghur (China) is available" do
      let(:available_langtag) { :"ug-CN" }

      it { expect(best_match).to be_nil }
    end
  end

  describe "Quality values" do
    # RFC 7231 Section 5.3.1: Quality values indicate relative preference.
    # Higher q-values indicate stronger preference; q=0 means "not acceptable".

    context "when I prefer Danish, but will accept British English and other types of English" do
      # "da, en-gb;q=0.8, en;q=0.7"
      let(:matcher) { described_class.new("da" => 1000, "en-gb" => 800, "en" => 700) }

      context "when Danish, British English and English are available" do
        let(:available_langtags) { %i[da en-GB en] }

        it { expect(best_match).to be :da }
      end

      context "when Danish and British English are available" do
        let(:available_langtags) { %i[da en-GB] }

        it { expect(best_match).to be :da }
      end

      context "when Danish and English are available" do
        let(:available_langtags) { %i[da en] }

        it { expect(best_match).to be :da }
      end

      context "when only Danish is available" do
        let(:available_langtags) { %i[da] }

        it { expect(best_match).to be :da }
      end

      context "when British English and English are available" do
        let(:available_langtags) { %i[en-GB en] }

        it { expect(best_match).to be :"en-GB" }
      end

      context "when only British English is available" do
        let(:available_langtags) { %i[en-GB] }

        it { expect(best_match).to be :"en-GB" }
      end

      context "when only English is available" do
        let(:available_langtags) { %i[en] }

        it { expect(best_match).to be :en }
      end

      context "when none of the preferred languages are available" do
        let(:available_langtags) { %i[fr de] }

        it { expect(best_match).to be_nil }
      end
    end

    context "when I accept German (Luxembourg), or any language except English" do
      # "de-LU, *;q=0.5, en;q=0"
      let(:matcher) { described_class.new("de-lu" => 1000, "*" => 500, "en" => 0) }

      context "when German (Luxembourg), English and Russian are available" do
        let(:available_langtags) { %i[de-LU en ru] }

        it { expect(best_match).to be :"de-LU" }
      end

      context "when German (Luxembourg) and English are available" do
        let(:available_langtags) { %i[de-LU en] }

        it { expect(best_match).to be :"de-LU" }
      end

      context "when German (Luxembourg) and Russian are available" do
        let(:available_langtags) { %i[de-LU ru] }

        it { expect(best_match).to be :"de-LU" }
      end

      context "when only German (Luxembourg) is available" do
        let(:available_langtags) { %i[de-LU] }

        it { expect(best_match).to be :"de-LU" }
      end

      context "when English and Russian are available" do
        let(:available_langtags) { %i[en ru] }

        it { expect(best_match).to be :ru }
      end

      context "when only English is available" do
        let(:available_langtags) { %i[en] }

        it { expect(best_match).to be_nil }
      end

      context "when only Russian is available" do
        let(:available_langtags) { %i[ru] }

        it { expect(best_match).to be :ru }
      end

      context "when no languages are available" do
        let(:available_langtags) { [] }

        it { expect(best_match).to be_nil }
      end
    end
  end

  describe "Case-insensitive matching" do
    # RFC 4647 Section 2: "Language tags and thus language ranges are to be
    # treated as case-insensitive."

    let(:available_langtags) { [available_langtag] }

    context "when the language range is stored in lowercase (as expected)" do
      # Matcher always receives lowercase keys from Parser
      let(:matcher) { described_class.new("en-nz" => 1000) }

      context "when the corresponding language is in uppercase" do
        let(:available_langtag) { :"EN-NZ" }

        it "preserves case" do
          expect(best_match).to be :"EN-NZ"
        end
      end

      context "when the corresponding language is in lowercase" do
        let(:available_langtag) { :"en-nz" }

        it "preserves case" do
          expect(best_match).to be :"en-nz"
        end
      end

      context "when the corresponding language is in mixed case" do
        let(:available_langtag) { :"En-Nz" }

        it "preserves case" do
          expect(best_match).to be :"En-Nz"
        end
      end

      context "when the corresponding language is in standard case" do
        let(:available_langtag) { :"en-NZ" }

        it "preserves case" do
          expect(best_match).to be :"en-NZ"
        end
      end
    end
  end

  describe "Identical quality values" do
    # When multiple languages have the same q-value, the order of declaration
    # in the Accept-Language header should be preserved (first declared wins).
    # Ruby's Hash preserves insertion order since Ruby 1.9.

    context "when two languages have the same q-value" do
      let(:available_langtags) { %i[en fr] }

      context "when English is declared first" do
        let(:matcher) { described_class.new("en" => 800, "fr" => 800) }

        it "prefers English (declared first)" do
          expect(best_match).to be :en
        end
      end

      context "when French is declared first" do
        let(:matcher) { described_class.new("fr" => 800, "en" => 800) }

        it "prefers French (declared first)" do
          expect(best_match).to be :fr
        end
      end
    end

    context "when three languages have the same q-value" do
      # "de;q=0.8, en;q=0.8, fr;q=0.8"
      let(:matcher) { described_class.new("de" => 800, "en" => 800, "fr" => 800) }
      let(:available_langtags) { %i[fr en de] }

      it "prefers German (declared first)" do
        expect(best_match).to be :de
      end

      context "when German is not available" do
        let(:available_langtags) { %i[fr en] }

        it "prefers English (declared second)" do
          expect(best_match).to be :en
        end
      end

      context "when only French is available" do
        let(:available_langtags) { %i[fr] }

        it "returns French" do
          expect(best_match).to be :fr
        end
      end
    end

    context "when mixed with different quality values" do
      # "da, en;q=0.8, fr;q=0.8, de;q=0.7"
      let(:matcher) { described_class.new("da" => 1000, "en" => 800, "fr" => 800, "de" => 700) }

      context "when all languages are available" do
        let(:available_langtags) { %i[de fr en da] }

        it "prefers Danish (highest q-value)" do
          expect(best_match).to be :da
        end
      end

      context "when Danish is not available" do
        let(:available_langtags) { %i[de fr en] }

        it "prefers English (same q-value as French, but declared first)" do
          expect(best_match).to be :en
        end
      end

      context "when only German is available" do
        let(:available_langtags) { %i[de] }

        it "returns German (lowest q-value but only option)" do
          expect(best_match).to be :de
        end
      end
    end

    context "when all languages have implicit q-value of 1" do
      # "en, fr, de" (all with q=1.0)
      let(:matcher) { described_class.new("en" => 1000, "fr" => 1000, "de" => 1000) }
      let(:available_langtags) { %i[de fr en] }

      it "prefers English (declared first)" do
        expect(best_match).to be :en
      end
    end
  end

  describe "RFC 4647 Section 3.3.1 Basic Filtering prefix matching" do
    # RFC 4647 Section 3.3.1: "A language-range matches a language-tag if it
    # exactly equals the tag, or if it exactly equals a prefix of the tag such
    # that the first character following the prefix is '-'."

    let(:available_langtags) { [available_langtag] }

    context "when language range is 'zh'" do
      let(:matcher) { described_class.new("zh" => 1000) }

      context "when available tag is 'zh' (exact match)" do
        let(:available_langtag) { :zh }

        it "matches exactly" do
          expect(best_match).to be :zh
        end
      end

      context "when available tag is 'zh-TW' (valid prefix match)" do
        let(:available_langtag) { :"zh-TW" }

        it "matches because 'zh' is followed by '-'" do
          expect(best_match).to be :"zh-TW"
        end
      end

      context "when available tag is 'zh-Hans-CN' (valid nested prefix match)" do
        let(:available_langtag) { :"zh-Hans-CN" }

        it "matches because 'zh' is followed by '-'" do
          expect(best_match).to be :"zh-Hans-CN"
        end
      end

      context "when available tag is 'zhx' (invalid: not followed by '-')" do
        let(:available_langtag) { :zhx }

        it "does NOT match because 'zh' is followed by 'x', not '-'" do
          expect(best_match).to be_nil
        end
      end

      context "when available tag is 'zhx-Hans' (invalid: different language code)" do
        let(:available_langtag) { :"zhx-Hans" }

        it "does NOT match because 'zhx' is a different ISO 639-3 code" do
          expect(best_match).to be_nil
        end
      end
    end

    context "when language range is 'en'" do
      let(:matcher) { described_class.new("en" => 1000) }

      context "when available tag is 'english' (invalid: not a subtag)" do
        let(:available_langtag) { :english }

        it "does NOT match because 'en' is not followed by '-'" do
          expect(best_match).to be_nil
        end
      end

      context "when available tag is 'en-US'" do
        let(:available_langtag) { :"en-US" }

        it "matches via prefix" do
          expect(best_match).to be :"en-US"
        end
      end

      context "when available tag is 'en-Latn-US'" do
        let(:available_langtag) { :"en-Latn-US" }

        it "matches via prefix (multiple subtags)" do
          expect(best_match).to be :"en-Latn-US"
        end
      end
    end

    context "when language range is 'en-us'" do
      let(:matcher) { described_class.new("en-us" => 1000) }

      context "when available tag is 'en'" do
        let(:available_langtag) { :en }

        it "does NOT match (more specific range cannot match less specific tag)" do
          expect(best_match).to be_nil
        end
      end

      context "when available tag is 'en-US'" do
        let(:available_langtag) { :"en-US" }

        it "matches exactly" do
          expect(best_match).to be :"en-US"
        end
      end

      context "when available tag is 'en-GB'" do
        let(:available_langtag) { :"en-GB" }

        it "does NOT match (different region)" do
          expect(best_match).to be_nil
        end
      end
    end

    context "when language range is 'de-de'" do
      # Example from RFC 4647 Section 3.3.1
      let(:matcher) { described_class.new("de-de" => 1000) }

      context "when available tag is 'de-DE-1996'" do
        let(:available_langtag) { :"de-DE-1996" }

        it "matches via prefix" do
          expect(best_match).to be :"de-DE-1996"
        end
      end

      context "when available tag is 'de-Deva'" do
        let(:available_langtag) { :"de-Deva" }

        it "does NOT match (de-de is not a prefix of de-Deva)" do
          expect(best_match).to be_nil
        end
      end

      context "when available tag is 'de-Latn-DE'" do
        let(:available_langtag) { :"de-Latn-DE" }

        it "does NOT match (de-de is not a prefix of de-Latn-DE)" do
          expect(best_match).to be_nil
        end
      end
    end

    context "with exclusions (q=0) respecting hyphen boundary" do
      # "*, zh;q=0"
      let(:matcher) { described_class.new("*" => 1000, "zh" => 0) }

      context "when 'zh' is excluded" do
        context "when 'zh-TW' is available" do
          let(:available_langtag) { :"zh-TW" }

          it "excludes 'zh-TW' because it matches the 'zh' prefix" do
            expect(best_match).to be_nil
          end
        end

        context "when 'zhx-Hans' is available" do
          let(:available_langtag) { :"zhx-Hans" }

          it "accepts 'zhx-Hans' because 'zhx' does not match 'zh' prefix" do
            expect(best_match).to be :"zhx-Hans"
          end
        end
      end
    end

    context "with wildcard respecting hyphen boundary" do
      # "zh, *;q=0.5"
      let(:matcher) { described_class.new("zh" => 1000, "*" => 500) }
      let(:available_langtags) { %i[zh-TW zhx-Hans] }

      it "matches 'zh-TW' via prefix and 'zhx-Hans' via wildcard" do
        # 'zh-TW' matches 'zh' prefix (q=1.0)
        # 'zhx-Hans' does NOT match 'zh' prefix, so falls to wildcard (q=0.5)
        expect(best_match).to be :"zh-TW"
      end

      context "when only 'zhx-Hans' is available" do
        let(:available_langtags) { [:"zhx-Hans"] }

        it "matches via wildcard, not via 'zh' prefix" do
          expect(best_match).to be :"zhx-Hans"
        end
      end
    end
  end

  describe "Wildcard behavior" do
    # RFC 4647 Section 3.3.1: "The special range '*' in a language priority list
    # matches any tag. A protocol that uses language ranges MAY specify additional
    # rules about the semantics of '*'; for instance, HTTP/1.1 specifies that the
    # range '*' matches only languages not matched by any other range within an
    # 'Accept-Language' header."

    context "when wildcard is the only range" do
      let(:matcher) { described_class.new("*" => 1000) }
      let(:available_langtags) { %i[en fr de] }

      it "matches the first available language" do
        expect(best_match).to be :en
      end
    end

    context "when wildcard has lower priority than explicit ranges" do
      # "fr, *;q=0.5"
      let(:matcher) { described_class.new("fr" => 1000, "*" => 500) }

      context "when French is available" do
        let(:available_langtags) { %i[fr en] }

        it "prefers French (explicit match)" do
          expect(best_match).to be :fr
        end
      end

      context "when only non-French languages are available" do
        let(:available_langtags) { %i[en de] }

        it "matches via wildcard" do
          expect(best_match).to be :en
        end
      end
    end
  end

  describe "Wildcard exclusion (q=0)" do
    # RFC 7231 Section 5.3.1: A q-value of 0 means "not acceptable".
    #
    # When combined with the wildcard, "*;q=0" means "all languages not
    # explicitly listed are not acceptable".

    context "when '*;q=0' is used alone" do
      let(:matcher) { described_class.new("*" => 0) }
      let(:available_langtags) { %i[en fr de] }

      it "rejects all languages" do
        expect(best_match).to be_nil
      end
    end

    context "when '*;q=0' is combined with explicit preferences" do
      # "en, fr;q=0.8, *;q=0"
      let(:matcher) { described_class.new("en" => 1000, "fr" => 800, "*" => 0) }

      context "when matching an explicitly listed language" do
        let(:available_langtags) { %i[en] }

        it "accepts the explicitly listed language" do
          expect(best_match).to be :en
        end
      end

      context "when matching a prefix of an explicitly listed language" do
        let(:available_langtags) { %i[en-GB] }

        it "accepts via prefix matching" do
          expect(best_match).to be :"en-GB"
        end
      end

      context "when matching a non-listed language" do
        let(:available_langtags) { %i[de] }

        it "rejects the non-listed language" do
          expect(best_match).to be_nil
        end
      end

      context "when both listed and non-listed languages are available" do
        let(:available_langtags) { %i[en fr de ja] }

        it "returns the best explicitly listed match" do
          expect(best_match).to be :en
        end
      end
    end

    context "when '*;q=0' is combined with explicit exclusions" do
      # "en, de;q=0, *;q=0"
      let(:matcher) { described_class.new("en" => 1000, "de" => 0, "*" => 0) }
      let(:available_langtags) { %i[en de fr] }

      it "accepts only the explicitly allowed language" do
        # en: explicitly allowed (q=1)
        # de: explicitly excluded (q=0)
        # fr: excluded by wildcard (q=0)
        expect(best_match).to be :en
      end

      context "when only excluded languages are available" do
        let(:available_langtags) { %i[de fr] }

        it "rejects all" do
          expect(best_match).to be_nil
        end
      end
    end

    context "when wildcard has positive quality and specific exclusions" do
      # "*, en;q=0"
      let(:matcher) { described_class.new("*" => 1000, "en" => 0) }

      context "when matching a non-excluded language" do
        let(:available_langtags) { %i[fr] }

        it "accepts via wildcard" do
          expect(best_match).to be :fr
        end
      end

      context "when matching an excluded language" do
        let(:available_langtags) { %i[en] }

        it "rejects the excluded language" do
          expect(best_match).to be_nil
        end
      end

      context "when matching a prefix of an excluded language" do
        let(:available_langtags) { %i[en-GB] }

        it "rejects via prefix exclusion" do
          expect(best_match).to be_nil
        end
      end

      context "when both excluded and non-excluded languages are available" do
        let(:available_langtags) { %i[en fr de] }

        it "returns a non-excluded language via wildcard" do
          # en is excluded, fr and de match via wildcard
          # Returns first non-excluded available tag
          expect(best_match).to be :fr
        end
      end
    end
  end

  describe "Empty available languages" do
    let(:matcher) { described_class.new("en" => 1000, "fr" => 1000) }
    let(:available_langtags) { [] }

    it "returns nil" do
      expect(best_match).to be_nil
    end
  end

  describe "Empty languages_range (no preferences)" do
    let(:matcher) { described_class.new }
    let(:available_langtags) { %i[en fr] }

    it "returns nil (no languages match)" do
      expect(best_match).to be_nil
    end
  end

  describe "Return type" do
    let(:matcher) { described_class.new("en" => 1000) }
    let(:available_langtags) { %i[en] }

    it "returns a Symbol" do
      expect(best_match).to be_instance_of(Symbol)
    end

    it "returns the exact Symbol passed in" do
      expect(best_match).to be :en
    end

    context "with complex tag" do
      let(:matcher) { described_class.new("zh-hant" => 1000) }
      let(:available_langtags) { [:"zh-Hant-TW"] }

      it "returns the exact Symbol passed in" do
        expect(best_match).to be :"zh-Hant-TW"
      end
    end
  end

  describe "Internal state" do
    describe "#excluded_langtags" do
      context "with exclusions" do
        let(:matcher) { described_class.new("*" => 1000, "en" => 0, "de" => 0) }

        it "contains excluded language ranges" do
          expect(matcher.excluded_langtags).to eq(Set["en", "de"])
        end

        it "does not contain the wildcard even when *;q=0" do
          matcher_with_wildcard_exclusion = described_class.new("en" => 1000, "*" => 0)
          expect(matcher_with_wildcard_exclusion.excluded_langtags.include?("*")).to be false
        end
      end

      context "without exclusions" do
        let(:matcher) { described_class.new("en" => 1000, "fr" => 800) }

        it "is empty" do
          expect(matcher.excluded_langtags).to be_empty
        end
      end
    end

    describe "#preferred_langtags" do
      context "with multiple quality values" do
        let(:matcher) { described_class.new("da" => 1000, "en-gb" => 800, "en" => 700) }

        it "is sorted by descending quality" do
          expect(matcher.preferred_langtags).to eq(%w[da en-gb en])
        end
      end

      context "with exclusions" do
        let(:matcher) { described_class.new("en" => 1000, "de" => 0, "fr" => 800) }

        it "contains only languages with positive quality" do
          expect(matcher.preferred_langtags).to eq(%w[en fr])
        end

        it "does not include excluded languages" do
          expect(matcher.preferred_langtags.include?("de")).to be false
        end
      end

      context "when all languages have the same quality" do
        let(:matcher) { described_class.new("en" => 800, "fr" => 800, "de" => 800) }

        it "preserves insertion order" do
          expect(matcher.preferred_langtags).to eq(%w[en fr de])
        end
      end
    end
  end
end
