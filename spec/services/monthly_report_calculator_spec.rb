# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonthlyReportCalculator do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, created_at: Date.new(2023, 5, 15)) }
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
      end

      it '売上が正しく計算されること' do
        expect(calculator.revenue).to eq(100.0)
      end

      it '支払い手数料が正しく計算されること' do
        expect(calculator.payment_fee).to eq(10.0)
      end

      it '配送コストが正しく計算されること' do
        expect(calculator.shipping_cost).to eq(2000)
      end

      it '調達コストが正しく計算されること' do
        expect(calculator.procurement_cost).to eq(5000)
      end

      it '総コストが正しく計算されること' do
        # 手数料: 10 USD = 1,500 JPY
        # 送料: 2,000 JPY
        # 仕入: 5,000 JPY
        # その他: 1,000 JPY (500 + 300 + 200)
        # 合計コスト = 1,500 + 2,000 + 5,000 + 1,000 = 9,500 JPY
        expect(calculator.total_cost).to eq(9500)
      end

      it '利益が正しく計算されること' do
        # 売上: 100 USD = 15,000 JPY
        # 合計コスト: 9,500 JPY
        # 利益 = 15,000 - 9,500 = 5,500 JPY
        expect(calculator.profit).to eq(5500)
      end

      it '利益率が正しく計算されること' do
        # 利益: 5,500 JPY
        # 売上: 15,000 JPY
        # 利益率 = 5,500 / 15,000 = 36.67%
        expect(calculator.profit_rate).to be_within(0.1).of(36.67)
      end
    end

    context 'データが欠損している場合' do
      it '売上データが欠損している場合を適切に処理すること' do
        expect(calculator.revenue).to eq(0.0)
        expect(calculator.profit).to eq(0)
        expect(calculator.profit_rate).to eq(0)
      end

      it '調達データが欠損している場合を適切に処理すること' do
        create(:sale, order: order, order_net_amount: 100.0)
        expect(calculator.procurement_cost).to eq(0)
      end

      it '配送データが欠損している場合を適切に処理すること' do
        create(:sale, order: order, order_net_amount: 100.0)
        expect(calculator.shipping_cost).to eq(0)
      end
    end
  end

  describe '#calculate_monthly_data' do
    let(:year) { 2023 }
    let(:month) { 5 }

    before do
      # 3つの注文を作成する (5月)
      3.times do |i|
        order = create(:order, user: user, created_at: Date.new(2023, 5, 10 + i))
        create(:sale, order: order, order_net_amount: 100.0)
        create(:payment_fee, order: order, fee_amount: 10.0)
        create(:shipment, order: order, customer_international_shipping: 2000)
        create(:procurement, order: order, purchase_price: 5000)
      end

      # 4月の注文を1つ作成
      april_order = create(:order, user: user, created_at: Date.new(2023, 4, 15))
      create(:sale, order: april_order, order_net_amount: 50.0)
    end

    it '月次データが正しく集計されること' do
      result = described_class.calculate_monthly_data(user.id, year, month)

      # 5月の注文が3つあるため、集計結果は3倍になる
      expect(result[:revenue]).to eq(300.0)
      expect(result[:payment_fee]).to eq(30.0)
      expect(result[:shipping_cost]).to eq(6000)
      expect(result[:procurement_cost]).to eq(15000)

      # 売上: 300 USD = 45,000 JPY
      # 手数料: 30 USD = 4,500 JPY
      # 送料: 6,000 JPY
      # 仕入: 15,000 JPY
      # 合計コスト = 4,500 + 6,000 + 15,000 = 25,500 JPY
      # 利益 = 45,000 - 25,500 = 19,500 JPY
      expect(result[:profit]).to eq(19500)

      # 利益率 = 19,500 / 45,000 = 43.33%
      expect(result[:profit_rate]).to be_within(0.1).of(43.33)
    end

    it '注文のない月は空のデータを返すこと' do
      result = described_class.calculate_monthly_data(user.id, 2023, 6)

      expect(result[:revenue]).to eq(0.0)
      expect(result[:payment_fee]).to eq(0.0)
      expect(result[:shipping_cost]).to eq(0)
      expect(result[:procurement_cost]).to eq(0)
      expect(result[:profit]).to eq(0)
      expect(result[:profit_rate]).to eq(0)
    end
  end
end
