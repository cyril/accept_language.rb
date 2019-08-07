# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe AcceptLanguage::Intersection do
  context 'when the case is different' do
    shared_examples 'a case-correct intersection' do | bcp47 |
      context 'two letter' do
        it 'finds the best language and return in given case' do
          actual = described_class.new('EN', :eN, two_letter_truncate: true, enforce_bcp47: bcp47).call
          expect(actual).to be(bcp47 ? :en : :eN)
        end

        it 'finds amongst longer tags and returns full match in given case' do
          actual = described_class.new('EN', :'en-NZ', two_letter_truncate: true, enforce_bcp47: bcp47).call
          expect(actual).to be :'en-NZ'
        end
      end

      context 'four letter' do
        context 'with truncation' do
          it 'truncates to two with exact match' do
            actual = described_class.new('EN-nz', :EN, :'fr-CA', two_letter_truncate: true, enforce_bcp47: bcp47).call
            expect(actual).to be(bcp47 ? :en : :EN)
          end

          it 'finds arbitrary two letter match even if there is an exact match' do # (because truncation is on; turn it off for precise matching)
            actual = described_class.new('EN-nz', :'eN-GB', :eN, :'eN-nz', :'fr-CA', two_letter_truncate: true, enforce_bcp47: bcp47).call
            expect(actual.to_s).to start_with(bcp47 ? 'en' : 'eN')
          end

          it 'finds the best available match based on two letter matching' do
            actual = described_class.new('EN-nz', :'EN-GB', :'fr-CA', two_letter_truncate: true, enforce_bcp47: bcp47).call
            expect(actual).to be(bcp47 ? :'en-GB' : :'EN-GB')
          end

          it 'handles no match' do
            actual = described_class.new('EN-nz', :fr, :'fr-CA', two_letter_truncate: true, enforce_bcp47: bcp47).call
            expect(actual).to be_nil
          end
        end

        context 'without truncation' do
          it 'finds exact match and preserves case' do
            actual = described_class.new('en-nz', :'EN-NZ', :'fr-CA', two_letter_truncate: false, enforce_bcp47: bcp47).call
            expect(actual).to be(bcp47 ? :'en-NZ' : :'EN-NZ')
          end

          it 'ignores a two letter match' do
            actual = described_class.new('EN-nz', :en, 'EN-GB', :'en-Nz', two_letter_truncate: false, enforce_bcp47: bcp47).call
            expect(actual).to be(bcp47 ? :'en-NZ' : :'en-Nz')
          end

          it 'does no truncation yielding no match' do
            actual = described_class.new('EN-nz', :en, 'fr-CA', 'en-GB', two_letter_truncate: false, enforce_bcp47: bcp47).call
            expect(actual).to be_nil
          end
        end
      end
    end

    context('preserve') { it_behaves_like('a case-correct intersection', false) }
    context('BCP 47'  ) { it_behaves_like('a case-correct intersection', true ) }
  end

  context 'when the two letter truncate option is used' do
    let(:raw_input)       { 'da, en-gb;q=0.8, ko;q=0.7' }
    let(:supported_langs) { %i[ar en ro] }

    context 'when enabled' do
      let(:two_letter_truncate) { true }

      it 'interprets "en-gb" as "en" and returns english' do
        actual = described_class.new(raw_input, *supported_langs, two_letter_truncate: two_letter_truncate).call
        expect(actual).to be :en
      end
    end

    context 'when disabled' do
      let(:two_letter_truncate) { false }

      it 'cannot interpret "en-gb" as "en" and returns nothing' do
        actual = described_class.new(raw_input, *supported_langs, two_letter_truncate: two_letter_truncate).call
        expect(actual).to be nil
      end
    end
  end

  context 'when the best preferred language is supported by the server' do
    let(:raw_input)       { 'zh, ko;q=0.7' }
    let(:supported_langs) { %i[zh ko] }

    it 'returns the best preferred language' do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be :zh
    end
  end

  context 'when the best preferred languages are not available' do
    let(:raw_input)       { 'zh, ko;q=0.7' }
    let(:supported_langs) { %i[ko] }

    it 'returns the next preferred languages' do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be :ko
    end
  end

  context 'when preferred languages are not available at all' do
    let(:raw_input)       { 'zh, ko;q=0.7' }
    let(:supported_langs) { %i[fr it de] }

    it 'returns nothing' do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be nil
    end
  end

  context 'when using a wildcard' do
    let(:raw_input)       { 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' }
    let(:supported_langs) { %i[ja] }

    it 'returns a supported language' do
      actual = described_class.new(raw_input, *supported_langs).call
      expect(actual).to be :ja
    end
  end

  context 'when the only language that is supported is not acceptable' do
    let(:supported_langs) { %i[fr] }

    context 'without a wildcard' do
      let(:raw_input) { 'de, zh;q=0.4, fr;q=0' }

      it 'returns nothing' do
        actual = described_class.new(raw_input, *supported_langs).call
        expect(actual).to be nil
      end
    end

    context 'with a wildcard' do
      let(:raw_input) { 'de, zh;q=0.4, *;q=0.5, fr;q=0' }

      it 'returns nothing' do
        actual = described_class.new(raw_input, *supported_langs).call
        expect(actual).to be nil
      end
    end
  end

  context 'README.md' do
    it 'examples work' do
      expect( AcceptLanguage.intersection('da, en-gb;q=0.8, en;q=0.7', :ja, :ro, :da)    ).to be(:da)
      expect( AcceptLanguage.intersection('da, en-gb;q=0.8, en;q=0.7', :ja, :ro)         ).to be(nil)
      expect( AcceptLanguage.intersection('fr-CH', :'fr-CA', two_letter_truncate: false) ).to be(nil)
      expect( AcceptLanguage.intersection('fr-CH', :'fr-CA', two_letter_truncate: true)  ).to be(:'fr-CA') # Matches on 'fr', but *still returns a supported language*
      expect( AcceptLanguage.intersection('de, zh;q=0.4, fr;q=0', :fr)                   ).to be(nil)
      expect( AcceptLanguage.intersection('de, zh;q=0.4, *;q=0.5, fr;q=0', :fr)          ).to be(nil)
      expect( AcceptLanguage.intersection('de, zh;q=0.4, *;q=0.5, fr;q=0', :ar)          ).to be(:ar)
    end
  end
end
