# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe AcceptLanguage::Parser do
  context 'without a wildcard' do
    let(:raw_input) { 'da, en-gb;q=0.8, en;q=0.7' }

    it 'orders the tags with their respective quality' do
      actual = described_class.new(raw_input).call
      expect(actual).to eq %i[da en-gb en]
    end
  end

  context 'with a wildcard' do
    let(:raw_input) { 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' }

    it 'orders the tags with their respective quality' do
      actual = described_class.new(raw_input).call
      expect(actual).to eq %i[fr-ch fr en de *]
    end
  end
end
