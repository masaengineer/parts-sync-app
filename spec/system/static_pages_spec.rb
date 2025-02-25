require 'rails_helper'

RSpec.describe '静的ページ', type: :system do
  describe 'プライバシーポリシーページ', skip: 'ルートが存在しないため' do
    it 'プライバシーポリシーページが表示されること' do
      visit privacy_policy_path

      expect(page).to have_content('プライバシーポリシー')
      # 他にもプライバシーポリシーページにあるべき内容のテスト
    end
  end

  describe '利用規約ページ', skip: 'ルートが存在しないため' do
    it '利用規約ページが表示されること' do
      visit terms_of_service_path

      expect(page).to have_content('利用規約')
      # 他にも利用規約ページにあるべき内容のテスト
    end
  end
end
