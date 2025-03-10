require 'rails_helper'

RSpec.describe 'ユーザーログイン', type: :system do
  let(:user) { create(:user) }

  describe 'ログインフォーム' do
    context '有効な情報を入力した場合' do
      it 'ログインできること' do
        visit new_user_session_path

        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'password123'

        click_button 'ログイン'

        expect(page).to have_content('ログインしました')
        # ダッシュボードにリダイレクトされることを確認
        expect(current_path).to eq root_path
      end
    end

    context '無効な情報を入力した場合' do
      it 'ログインできないこと' do
        visit new_user_session_path

        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'wrong_password'

        click_button 'ログイン'

        expect(page).to have_content('メールアドレスまたはパスワードが違います')
        expect(current_path).to eq new_user_session_path
      end
    end
  end

  # JavaScriptが必要なテストは一時的にスキップ
  # Docker環境での実行時に追加設定が必要なため
  describe 'ログアウト', skip: 'Docker環境でのJSテストは別途設定が必要' do
    it 'ログアウトできること', js: true do
      # ログイン
      sign_in user
      visit root_path

      # ユーザーメニューを開く（実際のUIに合わせて調整してください）
      find('.user-menu-button').click

      # ログアウトリンクをクリック
      click_link 'ログアウト'

      expect(page).to have_content('ログアウトしました')
    end
  end
end
