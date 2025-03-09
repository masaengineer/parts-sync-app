require 'rails_helper'

RSpec.describe MonthlyReport::Service do
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
      skip '月次レポート機能の実装中のため'
    end

    it '各月のデータに必要なメトリクスが含まれていること' do
      skip '月次レポート機能の実装中のため'
    end
  end

  describe '計算ロジック' do
    it '売上高が正しく計算されること' do
      skip '月次レポート機能の実装中のため'
    end

    it '原価が正しく計算されること' do
      skip '月次レポート機能の実装中のため'
    end

    it '粗利が正しく計算されること' do
      skip '月次レポート機能の実装中のため'
    end

    it '販管費が正しく計算されること' do
      skip '月次レポート機能の実装中のため'
    end

    it '限界利益が正しく計算されること' do
      skip '月次レポート機能の実装中のため'
    end

    it '限界利益率が正しく計算されること' do
      skip '月次レポート機能の実装中のため'
    end

    context '売上高が0の場合' do
      before do
        # 売上が0の注文を作成
        zero_revenue_order = create(:order, user: user, sale_date: Date.new(year, 2, 15))
        create(:sale, order: zero_revenue_order, order_net_amount: 0)
      end

      it '限界利益率は0を返すこと' do
        skip '月次レポート機能の実装中のため'
      end
    end
  end
end
