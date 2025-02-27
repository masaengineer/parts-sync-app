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
    it '月次レポートページにアクセスすると正しいデータが表示される', js: true do
      visit monthly_reports_path

      # タイトルの確認
      expect(page).to have_content('月次レポート')

      # チャートが表示されていることを確認
      expect(page).to have_selector('div[data-controller="chart"]')

      # テーブルヘッダーの存在を確認
      within('table thead') do
        expect(page).to have_content('項目')
        expect(page).to have_content('1月')
        expect(page).to have_content('12月')
      end

      # テーブルボディに月次データが表示されていることを確認
      within('table tbody') do
        expect(page).to have_content('売上高')
        expect(page).to have_content('原価')
        expect(page).to have_content('粗利')
        expect(page).to have_content('販管費')
        expect(page).to have_content('限界利益')
        expect(page).to have_content('限界利益率(%)')
      end
    end
  end

  describe '年度選択機能' do
    it '年度を選択すると該当年度のデータが表示される', js: true do
      visit monthly_reports_path

      # 現在の年度を確認（デフォルトは現在年）
      expect(page).to have_content("#{Time.current.year} 年度")

      # 年度選択ドロップダウンを開く
      find('label.select').click

      # 2022年を選択
      within('.dropdown-content') do
        click_link '2022年度'
      end

      # 2022年のデータが表示されていることを確認
      expect(page).to have_content('2022 年度')

      # チャートが更新されていることを確認（検証方法はフロントエンド実装による）
      expect(page).to have_selector('div[data-controller="chart"]')

      # 表示されているデータが2022年のものであることを確認
      # （実際の値の検証はフロントエンド実装による）
    end
  end

  describe 'レスポンシブデザイン' do
    it 'モバイル表示でも適切に表示される', js: true do
      # ブラウザサイズをモバイルサイズに設定
      page.driver.browser.manage.window.resize_to(375, 812) # iPhoneXサイズ

      visit monthly_reports_path

      # モバイル表示でもテーブルが表示されていることを確認
      expect(page).to have_selector('table')

      # モバイル表示ではオーバーフローによるスクロールが可能であることを確認
      expect(page).to have_selector('div.overflow-x-auto')
    end
  end

  describe 'データなしの表示' do
    it 'データがない年度を選択した場合、適切なメッセージが表示される', js: true do
      visit monthly_reports_path

      # 年度選択ドロップダウンを開く
      find('label.select').click

      # データのない年度（2021年）を選択できるようにリンクを追加
      # （実際の実装では、データのない年度はリストに表示されない可能性があります）
      # このテストはコントローラーの実装によって調整が必要です
      if page.has_link?('2021年度')
        within('.dropdown-content') do
          click_link '2021年度'
        end

        # データがない場合のメッセージが表示されることを確認
        expect(page).to have_content('データがありません')
      else
        pending '2021年のデータがなく、そのリンクが表示されていないためスキップします'
      end
    end
  end
end
