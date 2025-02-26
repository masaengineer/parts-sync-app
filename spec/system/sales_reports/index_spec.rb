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
    it '売上レポートページにアクセスすると登録済みの商品が表示される', js: true do
      visit sales_reports_path

      # テーブルヘッダーの存在を確認
      within('table thead') do
        expect(page).to have_content('商品コード')
        # 他のヘッダー項目もここで確認
      end

      # テーブルボディに商品データが表示されていることを確認
      within('table tbody') do
        expect(page).to have_content('OIL-001')
        expect(page).to have_content('FIL-002')
      end
    end
  end

  describe '検索機能' do
    it '商品コードで検索できる', js: true do
      visit sales_reports_path

      within('.search-form') do
        fill_in 'q[sku_code_cont]', with: 'OIL'
        click_button '検索'
      end

      within('table tbody') do
        expect(page).to have_content('OIL-001')
        expect(page).not_to have_content('FIL-002')
        expect(page).not_to have_content('FIL-003')
        expect(page).not_to have_content('BRK-001')
      end
    end

    it '検索条件をクリアできる', js: true do
      visit sales_reports_path

      within('.search-form') do
        fill_in 'q[sku_code_cont]', with: 'OIL'
        click_button '検索'
      end

      # 検索結果が絞り込まれていることを確認
      within('table tbody') do
        expect(page).to have_content('OIL-001')
        expect(page).not_to have_content('FIL-002')
      end

      # クリアボタンをクリック
      click_link 'クリア'

      # 全件表示されていることを確認
      within('table tbody') do
        expect(page).to have_content('OIL-001')
        expect(page).to have_content('FIL-002')
        expect(page).to have_content('FIL-003')
        expect(page).to have_content('BRK-001')
      end
    end
  end
end
