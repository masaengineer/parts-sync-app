# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SalesReportCalculator do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }
  let(:calculator) { described_class.new(order) }

  describe '#calculate' do
    context '完全な注文データの場合' do
      before do
        # 売上データを作成
        create(:sale, order: order, order_net_amount: 100.0, order_gross_amount: 110.0)

        # 手数料データを作成
        create(:payment_fee, order: order, fee_amount: 10.0)

        # 配送データを作成
        create(:shipment, order: order, customer_international_shipping: 2000)

        # 調達データを作成
        create(:procurement,
          order: order,
          purchase_price: 5000,
          forwarding_fee: 500,
          option_fee: 300,
          handling_fee: 200
        )

        # 注文明細を作成
        seller_sku = create(:seller_sku, sku_code: 'SKU001')
        create(:order_line,
          order: order,
          seller_sku: seller_sku,
          quantity: 2,
          line_item_name: '商品A'
        )
      end

      it 'すべての値が正しく計算されること' do
        result = calculator.calculate

        # USD建ての計算
        expect(result[:revenue]).to eq(100.0)
        expect(result[:payment_fees]).to eq(10.0)

        # 円建ての計算（為替レート: 150.0）
        expect(result[:shipping_cost]).to eq(2000)
        expect(result[:procurement_cost]).to eq(5000)
        expect(result[:other_costs]).to eq(1000) # 500 + 300 + 200

        # 数量
        expect(result[:quantity]).to eq(2)

        # 利益計算（円建て）
        # 売上: 100 USD = 15,000 JPY
        # 手数料: 10 USD = 1,500 JPY
        # 送料: 2,000 JPY
        # 仕入: 5,000 JPY
        # その他: 1,000 JPY
        # 利益 = 15,000 - (1,500 + 2,000 + 5,000 + 1,000) = 5,500 JPY
        expect(result[:profit]).to eq(5500)

        # 利益率 = 5,500 / 15,000 = 36.67%
        expect(result[:profit_rate]).to be_within(0.1).of(36.67)

        # その他の情報
        expect(result[:sku_codes]).to eq('SKU001')
        expect(result[:product_names]).to eq('商品A')
      end
    end

    context 'データが欠損している場合' do
      it '売上データが欠損している場合を適切に処理すること' do
        result = calculator.calculate
        expect(result[:revenue]).to eq(0.0)
        expect(result[:profit]).to eq(0)
        expect(result[:profit_rate]).to eq(0)
      end

      it '調達データが欠損している場合を適切に処理すること' do
        create(:sale, order: order, order_net_amount: 100.0)
        result = calculator.calculate
        expect(result[:procurement_cost]).to eq(0)
        expect(result[:other_costs]).to eq(0)
      end

      it '配送データが欠損している場合を適切に処理すること' do
        create(:sale, order: order, order_net_amount: 100.0)
        result = calculator.calculate
        expect(result[:shipping_cost]).to eq(0)
      end
    end

    context '無効なデータの場合' do
      it '無効な少数値を適切に処理すること' do
        create(:procurement, order: order, purchase_price: 'invalid')
        result = calculator.calculate
        expect(result[:procurement_cost]).to eq(0)
      end
    end
  end
end
