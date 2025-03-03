require 'rails_helper'

RSpec.describe '商品管理機能', type: :system, skip: '現在は実装されていません' do
  let(:user) { create(:user) }
  let!(:seller_sku) { create(:seller_sku) }

  before do
    sign_in user
  end

  describe '一覧表示機能', skip: '現在は実装されていません' do
    it '商品一覧ページにアクセスすると登録済みの商品が表示される', js: true, skip: '現在は実装されていません' do
      # テストをスキップ: 該当機能は実装されていません
      # visit seller_skus_path
      # expect(page).to have_content(seller_sku.sku_code)
    end
  end

  # 現状の実装では新規登録機能が実装されていないためスキップ
  describe '新規登録機能', skip: '現在は実装されていません' do
    it '有効な情報で商品を新規登録できる', js: true do
      # テスト内容は実装時に追加
    end
  end

  # 現状の実装では編集機能が実装されていないためスキップ
  describe '編集機能', skip: '現在は実装されていません' do
    it '商品情報を編集できる', js: true do
      # テスト内容は実装時に追加
    end
  end

  # 現状の実装では削除機能が実装されていないためスキップ
  describe '削除機能', skip: '現在は実装されていません' do
    it '商品を削除できる', js: true do
      # テスト内容は実装時に追加
    end
  end
end
