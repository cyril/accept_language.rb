# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe AcceptLanguage::Intersection do
  context 'when the best preferred language is not in the same case' do
    let(:accepted_languages)  { 'DA' }
    let(:supported_languages) { %i[da] }

    it 'returns the best preferred language' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be :da
    end
  end

  context 'with the default truncate option' do
    let(:accepted_languages)  { 'da, en-gb;q=0.8, ko;q=0.7' }
    let(:supported_languages) { %i[ar en ro] }

    it 'returns the best preferred truncated language' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be :en
    end
  end

  context 'when the truncate option is enable' do
    let(:accepted_languages)  { 'da, en-gb;q=0.8, ko;q=0.7' }
    let(:supported_languages) { %i[ar en ro] }

    it 'returns the best preferred truncated language' do
      actual = described_class.new(accepted_languages, *supported_languages, truncate: true).call
      expect(actual).to be :en
    end
  end

  context 'when the truncate option is disable' do
    let(:accepted_languages)  { 'da, en-gb;q=0.8, ko;q=0.7' }
    let(:supported_languages) { %i[ar en ro] }

    it 'returns the best preferred truncated language' do
      actual = described_class.new(accepted_languages, *supported_languages, truncate: false).call
      expect(actual).to be nil
    end
  end

  context 'when the best preferred language is available' do
    let(:accepted_languages)  { 'da, en-gb;q=0.8, en;q=0.7' }
    let(:supported_languages) { %i[ar da ja ro] }

    it 'returns the best preferred language' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be :da
    end
  end

  context 'when preferred languages are not available' do
    let(:accepted_languages)  { 'da, en-gb;q=0.8, en;q=0.7' }
    let(:supported_languages) { %i[ar ja ro] }

    it 'returns nothing' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be nil
    end
  end

  context 'when a preferred language is available' do
    let(:accepted_languages)  { 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' }
    let(:supported_languages) { %i[en ja] }

    it 'returns the preferred language' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be :en
    end
  end

  context 'when a preferred language is not explicitly available' do
    let(:accepted_languages)  { 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' }
    let(:supported_languages) { %i[ja] }

    it 'returns any supported language' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be :ja
    end
  end

  context 'when the wildcard is the first choice' do
    let(:accepted_languages)  { '*;q=0.5, zh;q=0.4' }
    let(:supported_languages) { %i[ja] }

    it 'returns any supported language' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be :ja
    end
  end

  context 'when french is not an option' do
    let(:accepted_languages)  { 'fr;q=0, zh;q=0.4' }
    let(:supported_languages) { %i[fr] }

    it 'returns nothing' do
      actual = described_class.new(accepted_languages, *supported_languages).call
      expect(actual).to be nil
    end
  end
end
