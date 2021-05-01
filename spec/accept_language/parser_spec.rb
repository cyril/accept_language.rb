# frozen_string_literal: true

RSpec.describe AcceptLanguage::Parser do
  context "without a wildcard" do
    let(:raw_input) { "da, en-gb;q=0.8, en;q=0.7" }

    context "without two letter truncate" do
      it "orders the tags with their respective quality" do
        actual = described_class.call(raw_input, two_letter_truncate: false)
        expect(actual).to eq(da: 1.0, 'en-gb': 0.8, en: 0.7)
      end
    end

    context "with two letter truncate" do
      it "orders the tags with their respective quality" do
        actual = described_class.call(raw_input, two_letter_truncate: true)
        expect(actual).to eq(da: 1.0, en: 0.7)
      end
    end
  end

  context "with a wildcard" do
    let(:raw_input) { "fr, fr-CH;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5" }

    context "without two letter truncate" do
      it "orders the tags with their respective quality" do
        actual = described_class.call(raw_input, two_letter_truncate: false)
        expect(actual).to eq(fr: 1.0, 'fr-ch': 0.9, en: 0.8, de: 0.7, '*': 0.5)
      end
    end

    context "with two letter truncate" do
      it "orders the tags with their respective quality" do
        actual = described_class.call(raw_input, two_letter_truncate: true)
        expect(actual).to eq(fr: 1.0, en: 0.8, de: 0.7, '*': 0.5)
      end
    end
  end
end
