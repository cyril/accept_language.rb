# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe AcceptLanguage do
  let(:raw_input) { 'da, en-gb;q=0.8, en;q=0.7' }

  describe '.parse' do
    it 'returns a hash of tags with their respective quality' do
      actual = described_class.parse(raw_input)
      expect(actual).to eq(da: 1.0, 'en-gb': 0.8, en: 0.7)
    end
  end

  describe '.intersection' do
    let(:supported_langs) { %i[en ko] }

    it 'returns the more appropriate language' do
      actual = described_class.intersection(raw_input, *supported_langs)
      expect(actual).to be :en
    end
  end
end
