require 'rails_helper'

RSpec.describe 'ページネーション機能', type: :system, skip: '現在は実装されていません' do
  let(:user) { create(:user) }

  before do
    sign_in user
    # ページネーションをテストするため、多数の商品を作成
    create_list(:seller_sku, 30)
  end

  describe '商品一覧のページネーション', skip: '現在は実装されていません' do
    it 'ページネーションが表示され、ページを切り替えられる', js: true, skip: '現在は実装されていません' do
      # テストをスキップ: 該当機能は実装されていません
      # visit seller_skus_path
      # 
      # # デフォルトでは1ページ目が表示されていることを確認
      # expect(page).to have_css('.pagination')
      # 
      # # 商品数をカウント（デフォルトのページサイズ分表示されているはず）
      # first_page_count = all('.seller-sku-item').count
      # expect(first_page_count).to be > 0
      # expect(first_page_count).to be <= 15  # デフォルトのページサイズが15と仮定
      # 
      # # 2ページ目に移動
      # click_link '2'
      # 
      # # 2ページ目の商品が表示されていることを確認
      # # （テスト環境でのAjaxの応答を待つ）
      # expect(page).to have_css('.pagination')
      # 
      # # 異なる商品セットが表示されていることを確認
      # second_page_count = all('.seller-sku-item').count
      # expect(second_page_count).to be > 0
      # 
      # # 1ページ目に戻る
      # click_link '1'
      # 
      # # 1ページ目の商品が表示されていることを確認
      # expect(page).to have_css('.pagination')
    end

    it 'ページサイズを変更できる', js: true, skip: '現在は実装されていません' do
      # テストをスキップ: 該当機能は実装されていません
      # visit seller_skus_path
      # 
      # # デフォルトのページサイズでの商品数を記録
      # default_count = all('.seller-sku-item').count
      # 
      # # ページサイズを変更（セレクトボックスの名前はアプリケーションによって異なる場合がある）
      # select '30', from: 'per_page'
      # 
      # # ページサイズ変更後の商品数を確認
      # expect(all('.seller-sku-item').count).to be > default_count
    end
  end

  describe '検索結果のページネーション', skip: '現在は実装されていません' do
    before do
      # 検索用のデータを準備
      create_list(:seller_sku, 20, sku_code: 'TEST-SKU')
    end

    it '検索結果にもページネーションが適用される', js: true, skip: '現在は実装されていません' do
      # テストをスキップ: 該当機能は実装されていません
      # visit seller_skus_path
      # 
      # fill_in 'q[sku_code_cont]', with: 'TEST'
      # click_button '検索'
      # 
      # # 検索結果にページネーションが表示されていることを確認
      # expect(page).to have_css('.pagination')
      # 
      # # 検索結果の1ページ目の商品数を確認
      # first_page_count = all('.seller-sku-item').count
      # expect(first_page_count).to be > 0
      # expect(first_page_count).to be <= 15  # デフォルトのページサイズが15と仮定
      # 
      # # 検索結果の2ページ目に移動
      # click_link '2'
      # 
      # # 2ページ目も検索条件を満たす商品が表示されていることを確認
      # second_page_items = all('.seller-sku-item')
      # expect(second_page_items.count).to be > 0
      # 
      # # すべての表示されている商品が検索条件を満たすことを確認
      # second_page_items.each do |item|
      #   expect(item).to have_content('TEST')
      # end
    end
  end
end
