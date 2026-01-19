# frozen_string_literal: true

require_relative File.join("..", "spec_helper")

RSpec.describe AcceptLanguage::Matcher do
  let(:matcher) do
    described_class.new(**AcceptLanguage::Parser.new(field).languages_range)
  end

  let(:best_match) { matcher.call(*available_langtags) }

  context "when asking for Chinese (Taiwan)" do
    let(:available_langtags) { [available_langtag] }
    let(:field) { "zh-TW" }

    context "when Chinese is available" do
      let(:available_langtag) { "zh" }

      it { expect(best_match).to be_nil }
    end

    context "when Chinese (Hong Kong) is available" do
      let(:available_langtag) { "zh-HK" }

      it { expect(best_match).to be_nil }
    end

    context "when Chinese (Taiwan) is available" do
      let(:available_langtag) { "zh-TW" }

      it { expect(best_match).to eq "zh-TW" }
    end

    context "when Uyghur (China) is available" do
      let(:available_langtag) { "ug-CN" }

      it { expect(best_match).to be_nil }
    end
  end

  context "when asking for Chinese" do
    let(:available_langtags) { [available_langtag] }
    let(:field) { "zh" }

    context "when Chinese is available" do
      let(:available_langtag) { "zh" }

      it { expect(best_match).to eq "zh" }
    end

    context "when Chinese (Hong Kong) is available" do
      let(:available_langtag) { "zh-HK" }

      it { expect(best_match).to eq "zh-HK" }
    end

    context "when Chinese (Taiwan) is available" do
      let(:available_langtag) { "zh-TW" }

      it { expect(best_match).to eq "zh-TW" }
    end

    context "when Uyghur (China) is available" do
      let(:available_langtag) { "ug-CN" }

      it { expect(best_match).to be_nil }
    end
  end

  describe "Quality values" do
    context "when I prefer Danish, but will accept British English and other types of English" do
      let(:available_langtags) { [danish, british_english, english].compact }
      let(:field) { "da, en-gb;q=0.8, en;q=0.7" }

      context "when Danish is available" do
        let(:danish) { "da" }

        context "when British English is available" do
          let(:british_english) { "en-GB" }

          context "when English is available" do
            let(:english) { "en" }

            it { expect(best_match).to eq "da" }
          end

          context "when English is not available" do
            let(:english) { nil }

            it { expect(best_match).to eq "da" }
          end
        end

        context "when British English is not available" do
          let(:british_english) { nil }

          context "when English is available" do
            let(:english) { "en" }

            it { expect(best_match).to eq "da" }
          end

          context "when English is not available" do
            let(:english) { nil }

            it { expect(best_match).to eq "da" }
          end
        end
      end

      context "when Danish is not available" do
        let(:danish) { nil }

        context "when British English is available" do
          let(:british_english) { "en-GB" }

          context "when English is available" do
            let(:english) { "en" }

            it { expect(best_match).to eq "en-GB" }
          end

          context "when English is not available" do
            let(:english) { nil }

            it { expect(best_match).to eq "en-GB" }
          end
        end

        context "when British English is not available" do
          let(:british_english) { nil }

          context "when English is available" do
            let(:english) { "en" }

            it { expect(best_match).to eq "en" }
          end

          context "when English is not available" do
            let(:english) { nil }

            it { expect(best_match).to be_nil }
          end
        end
      end
    end

    context "when I accept German (Luxembourg), or any language except English" do
      let(:available_langtags) { [german_luxembourg, english, another_language].compact }
      let(:field) { "de-LU, *;q=0.5, en;q=0" }

      context "when German (Luxembourg) is available" do
        let(:german_luxembourg) { "de-LU" }

        context "when English is available" do
          let(:english) { "en" }

          context "when another language is available" do
            let(:another_language) { "ru" }

            it { expect(best_match).to eq "de-LU" }
          end

          context "when no other language is available" do
            let(:another_language) { nil }

            it { expect(best_match).to eq "de-LU" }
          end
        end

        context "when English is not available" do
          let(:english) { nil }

          context "when another language is available" do
            let(:another_language) { "ru" }

            it { expect(best_match).to eq "de-LU" }
          end

          context "when no other language is available" do
            let(:another_language) { nil }

            it { expect(best_match).to eq "de-LU" }
          end
        end
      end

      context "when German (Luxembourg) is not available" do
        let(:german_luxembourg) { nil }

        context "when English is available" do
          let(:english) { "en" }

          context "when another language is available" do
            let(:another_language) { "ru" }

            it { expect(best_match).to eq "ru" }
          end

          context "when no other language is available" do
            let(:another_language) { nil }

            it { expect(best_match).to be_nil }
          end
        end

        context "when English is not available" do
          let(:english) { nil }

          context "when another language is available" do
            let(:another_language) { "ru" }

            it { expect(best_match).to eq "ru" }
          end

          context "when no other language is available" do
            let(:another_language) { nil }

            it { expect(best_match).to be_nil }
          end
        end
      end
    end
  end

  describe "Case-insensitive" do
    let(:available_langtags) { [available_langtag] }

    context "when the field is in uppercase" do
      let(:field) { "EN-NZ" }

      context "when the corresponding language is in uppercase" do
        let(:available_langtag) { "EN-NZ" }

        it "preserves case" do
          expect(best_match).to eq "EN-NZ"
        end
      end

      context "when the corresponding language is in lowercase" do
        let(:available_langtag) { "en-nz" }

        it "preserves case" do
          expect(best_match).to eq "en-nz"
        end
      end
    end

    context "when the field is in lowercase" do
      let(:field) { "en-nz" }

      context "when the corresponding language is in uppercase" do
        let(:available_langtag) { "EN-NZ" }

        it "preserves case" do
          expect(best_match).to eq "EN-NZ"
        end
      end

      context "when the corresponding language is in lowercase" do
        let(:available_langtag) { "en-nz" }

        it "preserves case" do
          expect(best_match).to eq "en-nz"
        end
      end
    end
  end

  describe "Type-insensitive" do
    let(:available_langtags) { [available_langtag] }
    let(:field) { "en-NZ" }

    context "when the corresponding language is a string" do
      let(:available_langtag) { "en-NZ" }

      it "preserves type" do
        expect(best_match).to eq "en-NZ"
      end
    end

    context "when the corresponding language is a symbol" do
      let(:available_langtag) { :"en-NZ" }

      it "preserves type" do
        expect(best_match).to eq :"en-NZ"
      end
    end
  end

  describe "RFC 2616 Section 14.4 prefix matching" do
    let(:available_langtags) { [available_langtag] }

    # RFC 2616: "A language-range matches a language-tag if it exactly equals
    # the tag, or if it exactly equals a prefix of the tag such that the first
    # tag character following the prefix is '-'."

    context "when language-range is 'zh'" do
      let(:field) { "zh" }

      context "when available tag is 'zh' (exact match)" do
        let(:available_langtag) { "zh" }

        it "matches exactly" do
          expect(best_match).to eq "zh"
        end
      end

      context "when available tag is 'zh-TW' (valid prefix match)" do
        let(:available_langtag) { "zh-TW" }

        it "matches because 'zh' is followed by '-'" do
          expect(best_match).to eq "zh-TW"
        end
      end

      context "when available tag is 'zh-Hans-CN' (valid nested prefix match)" do
        let(:available_langtag) { "zh-Hans-CN" }

        it "matches because 'zh' is followed by '-'" do
          expect(best_match).to eq "zh-Hans-CN"
        end
      end

      context "when available tag is 'zhx' (invalid: not followed by '-')" do
        let(:available_langtag) { "zhx" }

        it "does NOT match because 'zh' is followed by 'x', not '-'" do
          expect(best_match).to be_nil
        end
      end

      context "when available tag is 'zhx-Hans' (invalid: different language code)" do
        let(:available_langtag) { "zhx-Hans" }

        it "does NOT match because 'zhx' is a different ISO 639-3 code" do
          expect(best_match).to be_nil
        end
      end
    end

    context "when language-range is 'en'" do
      let(:field) { "en" }

      context "when available tag is 'english' (invalid: not a subtag)" do
        let(:available_langtag) { "english" }

        it "does NOT match because 'en' is not followed by '-'" do
          expect(best_match).to be_nil
        end
      end
    end

    context "with exclusions (q=0) respecting hyphen boundary" do
      let(:field) { "*, zh;q=0" }

      context "when 'zh' is excluded" do
        context "when 'zh-TW' is available" do
          let(:available_langtag) { "zh-TW" }

          it "excludes 'zh-TW' because it matches the 'zh' prefix" do
            expect(best_match).to be_nil
          end
        end

        context "when 'zhx-Hans' is available" do
          let(:available_langtag) { "zhx-Hans" }

          it "accepts 'zhx-Hans' because 'zhx' does not match 'zh' prefix" do
            expect(best_match).to eq "zhx-Hans"
          end
        end
      end
    end

    context "with wildcard respecting hyphen boundary" do
      let(:field) { "zh, *;q=0.5" }
      let(:available_langtags) { %w[zh-TW zhx-Hans] }

      it "matches 'zh-TW' via prefix and 'zhx-Hans' via wildcard" do
        # 'zh-TW' matches 'zh' prefix (q=1.0)
        # 'zhx-Hans' does NOT match 'zh' prefix, so falls to wildcard (q=0.5)
        expect(best_match).to eq "zh-TW"
      end

      context "when only 'zhx-Hans' is available" do
        let(:available_langtags) { ["zhx-Hans"] }

        it "matches via wildcard, not via 'zh' prefix" do
          expect(best_match).to eq "zhx-Hans"
        end
      end
    end
  end
end
