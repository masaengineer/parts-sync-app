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
          handling_fee: 3000
        )

        # オプション料金を作成
        create(:expense, :option_fee,
          year: year,
          month: month,
          order: order,
          amount: 2000,
          option_fee: 2000
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
      visit monthly_reports_path
      expect(page).to have_content('月次レポート')
      expect(page).to have_content('項目')
      expect(page).to have_content('合計')
    end
  end

  describe '年度選択機能' do
    it '年度を選択すると該当年度のデータが表示される' do
      visit monthly_reports_path

      # 現在の実装ではドロップダウンを使用しているため、直接リンクをクリックする
      find('label.select').click
      first('li a', text: '2022').click

      expect(page).to have_content('2022 年度')
    end
  end

  describe 'データ表示のテスト' do
    it 'テーブルとチャートが表示される' do
      visit monthly_reports_path

      # テーブルが表示されていることを確認
      expect(page).to have_selector('table.table')

      # チャートのコンテナが表示されていることを確認
      expect(page).to have_selector('[data-controller="chart"]')
    end
  end

  describe 'データなしの表示' do
    it 'データがない年度を選択した場合、適切に処理される' do
      # データがない年度を選択
      non_existent_year = Time.current.year + 2

      visit monthly_reports_path(year: non_existent_year)

      # データがない場合でもページが表示されることを確認
      expect(page).to have_content('年度')
    end
  end
end
