# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe AcceptLanguage::Parser do
  context 'without a wildcard' do
    let(:raw_input) { 'da, en-gb;q=0.8, en;q=0.7' }

    context 'without two letter truncate' do
      it 'orders the tags with their respective quality' do
        actual = described_class.call(raw_input, two_letter_truncate: false)
        expect(actual).to eq(da: 1.0, 'en-gb': 0.8, en: 0.7)
      end
    end

    context 'with two letter truncate' do
      it 'orders the tags with their respective quality' do
        actual = described_class.call(raw_input, two_letter_truncate: true)
        expect(actual).to eq(da: 1.0, en: 0.7)
      end
    end
  end

  context 'with a wildcard' do
    let(:raw_input) { 'fr, fr-CH;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' }

    context 'without two letter truncate' do
      it 'orders the tags with their respective quality' do
        actual = described_class.call(raw_input, two_letter_truncate: false)
        expect(actual).to eq(fr: 1.0, 'fr-ch': 0.9, en: 0.8, de: 0.7, '*': 0.5)
      end
    end

    context 'with two letter truncate' do
      it 'orders the tags with their respective quality' do
        actual = described_class.call(raw_input, two_letter_truncate: true)
        expect(actual).to eq(fr: 1.0, en: 0.8, de: 0.7, '*': 0.5)
      end
    end
  end

  context 'BCP 47' do
    it 'handles two letter' do
      expect(described_class.bcp47('EN')).to eql(:'en')
    end

    it 'handles two-two letter' do
      expect(described_class.bcp47(:'EN-en')).to eql(:'en-EN')
    end

    it 'handles multiple two letter subtags' do
      expect(described_class.bcp47('EN-en-za-fo')).to eql(:'en-EN-ZA-FO')
    end

    it 'handles two-four letter' do
      expect(described_class.bcp47(:'EN-inTL')).to eql(:'en-Intl')
    end

    it 'handles multiple four letter subtags' do
      expect(described_class.bcp47('EN-inTL-extr-tags')).to eql(:'en-Intl-Extr-Tags')
    end

    it 'handles two-letter subtags after singletons' do
      expect(described_class.bcp47(:'EN-en-x-zA-fo-y-Ra')).to eql(:'en-EN-x-za-FO-y-ra')
    end

    it 'handles four-letter subtags after singletons' do
      expect(described_class.bcp47('EN-inTL-x-extR-tags-y-moRe')).to eql(:'en-Intl-x-extr-Tags-y-more')
    end

    it 'handles non-2/4-letter subtags' do
      expect(described_class.bcp47(:'EN-enG-intl-heLLo-za')).to eql(:'en-eng-Intl-hello-ZA')
    end
  end
end
