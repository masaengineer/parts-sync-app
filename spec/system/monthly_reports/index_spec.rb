require 'rails_helper'

RSpec.describe '月次レポート', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
    # テストデータの作成
    create_data_for_year(2023)
    create_data_for_year(2022)
  end

  def create_data_for_year(year)
    (1..12).each do |month|
      date = Date.new(year, month, 15)
      multiplier = month / 2.0

      # 月ごとに複数の注文を作成
      3.times do |i|
        order = create(:order,
          user: user,
          sale_date: date,
          order_number: "#{year}#{month}#{i}"
        )

        # 売上データを作成
        create(:sale,
          order: order,
          order_net_amount: 100000 * multiplier
        )

        # 原価データを作成
        create(:procurement,
          order: order,
          purchase_price: 50000 * multiplier,
          forwarding_fee: 5000,
          option_fee: 2000,
          handling_fee: 3000
        )
      end

      # 販管費を作成（月ごとに1件）
      create(:expense,
        year: year,
        month: month,
        item_name: "月次経費",
        amount: 20000 * multiplier
      )
    end
  end

  describe '月次レポート一覧' do
    it '月次レポートページにアクセスすると正しいデータが表示される' do
      pending '月次レポート機能の実装中のため'
    end
  end

  describe '年度選択機能' do
    it '年度を選択すると該当年度のデータが表示される' do
      pending '月次レポート機能の実装中のため'
    end
  end

  describe 'レスポンシブデザイン' do
    it 'モバイル表示でも適切に表示される' do
      pending '月次レポート機能の実装中のため'
    end
  end

  describe 'データなしの表示' do
    it 'データがない年度を選択した場合、適切なメッセージが表示される' do
      pending '月次レポート機能の実装中のため'
    end
  end
end
