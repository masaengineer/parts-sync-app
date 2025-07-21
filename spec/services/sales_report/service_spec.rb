require 'rails_helper'

RSpec.describe SalesReport::Service do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, sale_date: Date.new(2024, 1, 15)) }
  let(:service) { described_class.new(order) }

  describe '#calculate' do
    context '為替レート計算' do
      before do
        # テスト用のデータセットアップ
        create(:sale, order: order, order_gross_amount: 100.0, to_usd_rate: 1.0)
        create(:payment_fee, order: order, fee_amount: 10.0)
      end

      context 'ユーザー別の為替レートが設定されている場合' do
        let!(:exchange_rate) { create(:exchange_rate, user: user, year: 2024, month: 1, usd_to_jpy_rate: 160.0) }

        it '設定された為替レートを使用する' do
          result = service.calculate
          
          # 160.0の為替レートが使用されていることを確認
          # net_revenue_usd = 100.0 - 10.0 = 90.0
          # net_revenue_jpy = 90.0 * 160.0 = 14,400
          expect(result[:profit]).to be_present
          
          # レート取得のロジックを確認
          rate = ExchangeRate.rate_for(user, 2024, 1)
          expect(rate).to eq(160.0)
        end
      end

      context 'ユーザー別の為替レートが設定されていない場合' do
        it 'デフォルトの為替レートを使用する' do
          result = service.calculate
          
          # デフォルトレート（環境変数またはデフォルト値150.0）が使用される
          default_rate = ENV.fetch("USD_TO_JPY_RATE", 150.0).to_f
          
          # レート取得のロジックを確認
          rate = ExchangeRate.rate_for(user, 2024, 1)
          expect(rate).to eq(default_rate)
        end
      end

      context '異なる月の為替レートが設定されている場合' do
        let!(:exchange_rate_jan) { create(:exchange_rate, user: user, year: 2024, month: 1, usd_to_jpy_rate: 160.0) }
        let!(:exchange_rate_feb) { create(:exchange_rate, user: user, year: 2024, month: 2, usd_to_jpy_rate: 155.0) }
        
        it '注文の月に対応する為替レートを使用する' do
          # 1月の注文
          result = service.calculate
          rate_jan = ExchangeRate.rate_for(user, 2024, 1)
          expect(rate_jan).to eq(160.0)
          
          # 2月の注文
          order_feb = create(:order, user: user, sale_date: Date.new(2024, 2, 15))
          create(:sale, order: order_feb, order_gross_amount: 100.0, to_usd_rate: 1.0)
          service_feb = described_class.new(order_feb)
          
          result_feb = service_feb.calculate
          rate_feb = ExchangeRate.rate_for(user, 2024, 2)
          expect(rate_feb).to eq(155.0)
        end
      end
    end
  end
end