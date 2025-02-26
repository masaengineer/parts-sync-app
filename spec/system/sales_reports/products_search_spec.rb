require 'rails_helper'

RSpec.describe '商品一覧', type: :system do
  let(:user) { create(:user) }
  before do
    sign_in user
    # テスト用の商品データを作成
    create(:seller_sku, sku_code: 'OIL-001')
    create(:seller_sku, sku_code: 'FIL-002')
    create(:seller_sku, sku_code: 'FIL-003')
    create(:seller_sku, sku_code: 'BRK-001')

    # テスト用の注文データを作成
    create(:order, order_number: 'ORD-12345', user: user)
    create(:order, order_number: 'ORD-67890', user: user)
  end

  describe '商品一覧表示' do
    it '商品一覧ページにアクセスすると登録済みの商品が表示される', js: true do
      visit seller_skus_path

      expect(page).to have_content('OIL-001')
      expect(page).to have_content('FIL-002')
      expect(page).to have_content('FIL-003')
      expect(page).to have_content('BRK-001')
    end
  end

  # 注意: 検索機能のテストは sales_reports/index_spec.rb に移動しました
  # 実際のアプリケーションでは検索機能は商品一覧ではなく売上レポート画面に実装されています
end
