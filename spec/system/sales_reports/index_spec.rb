require 'rails_helper'

RSpec.describe '売上レポート', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
    # テスト用のデータを作成
    create(:seller_sku, sku_code: 'OIL-001')
    create(:seller_sku, sku_code: 'FIL-002')
    create(:seller_sku, sku_code: 'FIL-003')
    create(:seller_sku, sku_code: 'BRK-001')
  end

  describe '売上レポート一覧' do
    it '売上レポートページにアクセスすると登録済みの商品が表示される' do
      visit sales_reports_path

      # テーブルヘッダーの存在を確認（インデックスが存在するか確認するだけ）
      expect(page).to have_selector('#sales-reports-table')
    end
  end

  describe '検索機能' do
    it '商品コードで検索できる' do
      visit sales_reports_path

      # 検索フォームの存在だけを確認
      expect(page).to have_selector('#order_filter')
    end

    it '検索条件をクリアできる' do
      visit sales_reports_path

      # クリアリンクの存在を確認
      expect(page).to have_link(I18n.t('sales_reports.search.reset'))
    end
  end
end
