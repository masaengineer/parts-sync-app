# frozen_string_literal: true

require 'rails_helper'

# ExchangeRateConcernをテストするためのダミークラス
class DummyClass
  include ExchangeRateConcern
end

RSpec.describe ExchangeRateConcern do
  let(:dummy) { DummyClass.new }

  describe '#convert_usd_to_jpy' do
    it 'USD金額を日本円に変換すること' do
      # 為替レートは150.0と設定されています
      result = dummy.convert_usd_to_jpy(100.0)
      expect(result).to eq(15000)
    end

    it '小数点以下の金額を正しく変換すること' do
      result = dummy.convert_usd_to_jpy(10.55)
      expect(result).to eq(1583) # 小数点以下は四捨五入
    end

    it 'nil値を0として扱うこと' do
      result = dummy.convert_usd_to_jpy(nil)
      expect(result).to eq(0)
    end

    it '負の値を正しく変換すること' do
      result = dummy.convert_usd_to_jpy(-100.0)
      expect(result).to eq(15000) # 絶対値を使用
    end

    it '0を正しく変換すること' do
      result = dummy.convert_usd_to_jpy(0)
      expect(result).to eq(0)
    end
  end

  describe 'USD_TO_JPY_RATE定数' do
    it '定数が定義されていること' do
      expect(DummyClass::USD_TO_JPY_RATE).to be_a(Float)
      expect(DummyClass::USD_TO_JPY_RATE).to be > 0
    end

    it '環境変数から値を取得できること' do
      original_rate = ENV['USD_TO_JPY_RATE']

      begin
        ENV['USD_TO_JPY_RATE'] = '170.0'
        # DummyClassを再定義して新しい環境変数の値を反映させる
        Object.send(:remove_const, :DummyClass)
        class DummyClass
          include ExchangeRateConcern
        end

        expect(DummyClass::USD_TO_JPY_RATE).to eq(170.0)
      ensure
        # テスト後に元の環境変数を復元
        if original_rate
          ENV['USD_TO_JPY_RATE'] = original_rate
        else
          ENV.delete('USD_TO_JPY_RATE')
        end
      end
    end
  end
end
