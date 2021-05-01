# frozen_string_literal: true

RSpec.describe AcceptLanguage::Intersection do
  context "when the case is different" do
    let(:raw_input)       { "EN" }
    let(:supported_langs) { %i[en] }

    it "finds the best language and return in downcase" do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be :en
    end
  end

  context "when the two letter truncate option is used" do
    let(:raw_input)       { "da, en-gb;q=0.8, ko;q=0.7" }
    let(:supported_langs) { %i[ar en ro] }

    context "when enable" do
      let(:two_letter_truncate) { true }

      it 'interprets "en-gb" as "en" and returns english' do
        actual = described_class.new(raw_input, *supported_langs, two_letter_truncate: two_letter_truncate).call
        expect(actual).to be :en
      end
    end

    context "when disable" do
      let(:two_letter_truncate) { false }

      it 'cannot interprets "en-gb" as "en" and returns nothing' do
        actual = described_class.new(raw_input, *supported_langs, two_letter_truncate: two_letter_truncate).call
        expect(actual).to be nil
      end
    end
  end

  context "when the best preferred language is supported by the server" do
    let(:raw_input)       { "zh, ko;q=0.7" }
    let(:supported_langs) { %i[zh ko] }

    it "returns the best preferred language" do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be :zh
    end
  end

  context "when the best preferred languages are not available" do
    let(:raw_input)       { "zh, ko;q=0.7" }
    let(:supported_langs) { %i[ko] }

    it "returns the next preferred languages" do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be :ko
    end
  end

  context "when preferred languages are not available at all" do
    let(:raw_input)       { "zh, ko;q=0.7" }
    let(:supported_langs) { %i[fr it de] }

    it "returns nothing" do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be nil
    end
  end

  context "when using a wildcard" do
    let(:raw_input)       { "fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5" }
    let(:supported_langs) { %i[ja] }

    it "returns a supported language" do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be :ja
    end
  end

  context "when the only language that is supported is not acceptable" do
    let(:supported_langs) { %i[fr] }

    context "without a wildcard" do
      let(:raw_input) { "de, zh;q=0.4, fr;q=0" }

      it "returns nothing" do
        actual = described_class.new(raw_input, *supported_langs).call
        expect(actual).to be nil
      end
    end

    context "with a wildcard" do
      let(:raw_input) { "de, zh;q=0.4, *;q=0.5, fr;q=0" }

      it "returns nothing" do
        actual = described_class.new(raw_input, *supported_langs).call
        expect(actual).to be nil
      end
    end
  end
end
