require 'rails_helper'

RSpec.describe CurrencyConverter do
  describe '.to_jpy' do
    it 'USDを円に正しく変換すること' do
      # スタブを使用して為替レートを固定
      allow(CurrencyConverter).to receive(:fetch_exchange_rate).with('USD', anything).and_return(135.0)

      result = CurrencyConverter.to_jpy(100.0, currency: 'USD')
      expect(result).to eq 13500
    end

    it 'EURを円に正しく変換すること' do
      allow(CurrencyConverter).to receive(:fetch_exchange_rate).with('EUR', anything).and_return(145.0)

      result = CurrencyConverter.to_jpy(100.0, currency: 'EUR')
      expect(result).to eq 14500
    end

    it 'GBPを円に正しく変換すること' do
      allow(CurrencyConverter).to receive(:fetch_exchange_rate).with('GBP', anything).and_return(170.0)

      result = CurrencyConverter.to_jpy(100.0, currency: 'GBP')
      expect(result).to eq 17000
    end

    it 'nilの場合は0を返すこと' do
      result = CurrencyConverter.to_jpy(nil, currency: 'USD')
      expect(result).to eq 0
    end

    it '0の場合は0を返すこと' do
      result = CurrencyConverter.to_jpy(0, currency: 'USD')
      expect(result).to eq 0
    end

    it '負の数を与えた場合も正しく変換すること' do
      allow(CurrencyConverter).to receive(:fetch_exchange_rate).with('USD', anything).and_return(135.0)

      result = CurrencyConverter.to_jpy(-100.0, currency: 'USD')
      expect(result).to eq -13500
    end

    it 'レートが指定された場合はそのレートを使用すること' do
      result = CurrencyConverter.to_jpy(100.0, currency: 'USD', rate: 140.0)
      expect(result).to eq 14000
    end
  end

  describe '.bulk_to_jpy' do
    it '複数の金額を一括で変換できること' do
      allow(CurrencyConverter).to receive(:fetch_exchange_rate).with('USD', anything).and_return(135.0)

      amounts = [ 100.0, 200.0, 300.0 ]
      results = CurrencyConverter.bulk_to_jpy(amounts, currency: 'USD')

      expect(results).to eq [ 13500, 27000, 40500 ]
    end
  end
end
