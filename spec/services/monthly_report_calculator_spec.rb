require 'rails_helper'

RSpec.describe MonthlyReportCalculator do
  let(:user) { create(:user) }
  let(:year) { 2023 }
  let(:month) { 1 }

  subject(:calculator) { described_class.new(user, year) }

  before do
    # テストデータの作成
    date = Date.new(year, month, 15)

    # 注文データの作成
    order = create(:order, user: user, sale_date: date)

    # 売上データの作成
    create(:sale, order: order, order_net_amount: 100000)

    # 原価データの作成
    create(:procurement,
      order: order,
      purchase_price: 50000,
      forwarding_fee: 5000,
      option_fee: 2000,
      handling_fee: 3000
    )

    # 販管費データの作成
    create(:expense, year: year, month: month, amount: 20000)
  end

  describe '#calculate' do
    it '12ヶ月分のデータを返すこと' do
      result = calculator.calculate
      expect(result.size).to eq(12)
      expect(result.first[:month]).to eq(1)
      expect(result.last[:month]).to eq(12)
    end

    it '各月のデータに必要なメトリクスが含まれていること' do
      result = calculator.calculate
      january_data = result.find { |d| d[:month] == 1 }

      expect(january_data).to include(
        :month,
        :revenue,
        :procurement_cost,
        :gross_profit,
        :expenses,
        :contribution_margin,
        :contribution_margin_rate
      )
    end
  end

  describe '計算ロジック' do
    it '売上高が正しく計算されること' do
      # privateメソッドをテストするためにsendを使用
      revenue = calculator.send(:calculate_revenue, month)
      expect(revenue).to eq(100000)
    end

    it '原価が正しく計算されること' do
      procurement_cost = calculator.send(:calculate_procurement_cost, month)
      expect(procurement_cost).to eq(60000) # 50000 + 5000 + 2000 + 3000
    end

    it '粗利が正しく計算されること' do
      gross_profit = calculator.send(:calculate_gross_profit, month)
      expect(gross_profit).to eq(40000) # 100000 - 60000
    end

    it '販管費が正しく計算されること' do
      expenses = calculator.send(:calculate_expenses, month)
      expect(expenses).to eq(20000)
    end

    it '限界利益が正しく計算されること' do
      contribution_margin = calculator.send(:calculate_contribution_margin, month)
      expect(contribution_margin).to eq(20000) # 40000 - 20000
    end

    it '限界利益率が正しく計算されること' do
      contribution_margin_rate = calculator.send(:calculate_contribution_margin_rate, month)
      expect(contribution_margin_rate).to eq(20) # (20000 / 100000) * 100
    end

    context '売上高が0の場合' do
      before do
        # 売上が0の注文を作成
        zero_revenue_order = create(:order, user: user, sale_date: Date.new(year, 2, 15))
        create(:sale, order: zero_revenue_order, order_net_amount: 0)
      end

      it '限界利益率は0を返すこと' do
        contribution_margin_rate = calculator.send(:calculate_contribution_margin_rate, 2)
        expect(contribution_margin_rate).to eq(0)
      end
    end
  end
end
