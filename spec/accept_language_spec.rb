# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe AcceptLanguage do
  describe '.parse' do
    let(:raw_input) { 'da, en-gb;q=0.8, en;q=0.7' }

    it 'orders the tags with their respective quality' do
      actual = described_class.parse(raw_input)
      expect(actual).to eq %i[da en-gb en]
    end
  end

  describe '.intersection' do
    let(:accepted_languages)  { 'da, en-gb;q=0.8' }
    let(:supported_languages) { %i[en ko] }

    it 'orders the tags with their respective quality' do
      actual = described_class.intersection(accepted_languages, *supported_languages)
      expect(actual).to be :en
    end
  end
end
