require 'rails_helper'

RSpec.describe 'ユーザー登録', type: :system do
  describe 'ユーザー新規登録' do
    context '有効な情報が入力された場合' do
      it '新規登録が成功すること', js: true do
        visit new_user_registration_path

        fill_in 'user[name]', with: 'テストユーザー'
        fill_in 'user[email]', with: 'test@example.com'
        fill_in 'user[password]', with: 'password123'
        fill_in 'user[password_confirmation]', with: 'password123'

        expect {
          click_button '登録する'
          expect(page).to have_content('アカウント登録が完了しました')
        }.to change(User, :count).by(1)

        # ダッシュボードにリダイレクトされることを確認
        expect(current_path).to eq root_path
      end
    end

    context '無効な情報が入力された場合' do
      it 'パスワードが一致しない場合はエラーが表示されること' do
        visit new_user_registration_path

        fill_in 'user[name]', with: 'テストユーザー'
        fill_in 'user[email]', with: 'test@example.com'
        fill_in 'user[password]', with: 'password123'
        fill_in 'user[password_confirmation]', with: 'different_password'

        click_button '登録する'

        expect(page).to have_content('パスワード（確認用）とパスワードの入力が一致しません')
        expect(current_path).to eq '/users'
      end

      it 'メールアドレスが既に使用されている場合はエラーが表示されること' do
        # 既存ユーザーの作成
        existing_user = create(:user, email: 'existing@example.com')

        visit new_user_registration_path

        fill_in 'user[name]', with: 'テストユーザー'
        fill_in 'user[email]', with: 'existing@example.com'
        fill_in 'user[password]', with: 'password123'
        fill_in 'user[password_confirmation]', with: 'password123'

        click_button '登録する'

        expect(page).to have_content('メールアドレスは既に使用されています')
        expect(current_path).to eq '/users'
      end
    end
  end

  describe 'ユーザープロフィール編集' do
    let(:user) { create(:user) }

    before do
      sign_in user
      visit edit_user_registration_path
    end

    it 'プロフィール情報を更新できること', js: true do
      fill_in 'user[name]', with: '更新されたユーザー名'
      fill_in 'user[current_password]', with: 'password123'

      click_button '更新する'

      expect(page).to have_content('アカウント情報を変更しました')

      # ユーザー名が更新されたことを確認
      user.reload
      expect(user.name).to eq '更新されたユーザー名'
    end

    it 'パスワードを変更できること', js: true do
      fill_in 'user[password]', with: 'new_password456'
      fill_in 'user[password_confirmation]', with: 'new_password456'
      fill_in 'user[current_password]', with: 'password123'

      click_button '更新する'

      expect(page).to have_content('アカウント情報を変更しました')

      # ログアウトして新しいパスワードでログインできることを確認
      click_link 'ログアウト'

      visit new_user_session_path
      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'new_password456'
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
    end
  end

  describe 'アカウント削除' do
    let(:user) { create(:user) }

    before do
      sign_in user
      visit edit_user_registration_path
    end

    it 'アカウントを削除できること', js: true do
      expect {
        page.accept_confirm do
          click_button 'アカウント削除'
        end

        expect(page).to have_content('アカウントを削除しました')
      }.to change(User, :count).by(-1)

      # ログインページにリダイレクトされることを確認
      expect(current_path).to eq new_user_session_path
    end
  end
end
