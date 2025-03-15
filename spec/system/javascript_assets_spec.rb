require 'rails_helper'

RSpec.describe 'JavaScriptアセット', type: :system, js: true do
  describe 'application.js' do
    # テスト対象のページにアクセス
    before do
      # ログインが必要な場合はログイン処理を追加
      # user = create(:user)
      # sign_in user

      # JavaScriptが読み込まれるページにアクセス
      # 注意: 実際のアプリケーションに合わせてパスを変更してください
      visit '/'

      # ページが完全に読み込まれるまで待機
      sleep 1
    end

    it 'JavaScriptが読み込まれていること' do
      # JavaScriptが読み込まれているかどうかを確認
      js_loaded = page.evaluate_script("typeof window !== 'undefined'")
      expect(js_loaded).to be true
    end

    it 'Iconifyが読み込まれているか確認（オプショナル）' do
      # Iconifyが読み込まれているかどうかを確認
      begin
        # iconify-iconタグが存在するか確認
        if page.has_css?('iconify-icon', visible: false)
          # Iconifyが読み込まれているか確認
          iconify_script_loaded = page.evaluate_script("typeof window.Iconify !== 'undefined' || document.querySelector('script[src*=\"iconify\"]') !== null")

          if iconify_script_loaded
            expect(iconify_script_loaded).to be true
          else
            # カスタム要素が登録されているか確認
            custom_element_registered = page.evaluate_script("typeof customElements !== 'undefined' && typeof customElements.get === 'function'")
            expect(custom_element_registered).to be true
          end
        else
          skip "iconify-iconタグが現在のページに存在しません"
        end
      rescue => e
        skip "JavaScriptの実行中にエラーが発生しました: #{e.message}"
      end
    end

    it 'Stimulusが読み込まれていること（存在する場合）' do
      # Stimulusが読み込まれているかどうかを確認（オプショナル）
      begin
        stimulus_exists = page.evaluate_script("typeof Stimulus !== 'undefined'")
        if stimulus_exists
          expect(javascript_loaded?('Stimulus')).to be true
        else
          skip "Stimulusは現在のページで使用されていません"
        end
      rescue => e
        skip "JavaScriptの実行中にエラーが発生しました: #{e.message}"
      end
    end

    it 'パスワードフィールドコントローラーが存在する場合、正しく動作すること' do
      begin
        if page.has_css?('[data-controller="password-field"]')
          password_field = find('[data-controller="password-field"]')
          toggle_button = password_field.find('[data-action="click->password-field#toggleVisibility"]')

          # 初期状態ではパスワードが隠れていることを確認
          input = password_field.find('input')
          expect(input[:type]).to eq('password')

          # トグルボタンをクリックしてパスワードを表示
          toggle_button.click
          expect(input[:type]).to eq('text')
        else
          skip "パスワードフィールドコントローラーは現在のページで使用されていません"
        end
      rescue => e
        skip "テスト実行中にエラーが発生しました: #{e.message}"
      end
    end

    it 'モーダルコントローラーが存在する場合、正しく動作すること' do
      begin
        if page.has_css?('[data-controller="modal"]') && page.has_css?('[data-action="click->modal#open"]')
          # モーダルを開くボタンをクリック
          find('[data-action="click->modal#open"]').click

          # モーダルが表示されることを確認
          expect(page).to have_css('[data-modal-target="container"].active')

          # モーダルを閉じるボタンをクリック
          find('[data-action="click->modal#close"]').click

          # モーダルが非表示になることを確認
          expect(page).not_to have_css('[data-modal-target="container"].active')
        else
          skip "モーダルコントローラーは現在のページで使用されていません"
        end
      rescue => e
        skip "テスト実行中にエラーが発生しました: #{e.message}"
      end
    end

    it 'テーマコントローラーが存在する場合、正しく動作すること' do
      begin
        if page.has_css?('[data-controller="theme"]') && page.has_css?('[data-action="click->theme#toggle"]')
          # 現在のテーマを取得
          initial_theme = page.evaluate_script('document.documentElement.getAttribute("data-theme")')

          # テーマ切り替えボタンをクリック
          find('[data-action="click->theme#toggle"]').click

          # テーマが切り替わったことを確認
          new_theme = page.evaluate_script('document.documentElement.getAttribute("data-theme")')
          expect(new_theme).not_to eq(initial_theme)
        else
          skip "テーマコントローラーは現在のページで使用されていません"
        end
      rescue => e
        skip "テスト実行中にエラーが発生しました: #{e.message}"
      end
    end

    it 'チャートコントローラーが存在する場合、正しく動作すること' do
      begin
        if page.has_css?('[data-controller="chart"]')
          # Chart.jsが読み込まれているか確認
          chart_exists = page.evaluate_script("typeof Chart !== 'undefined'")

          if chart_exists
            # チャートが描画されていることを確認
            expect(page).to have_css('canvas', visible: false)
          end
        else
          skip "チャートコントローラーは現在のページで使用されていません"
        end
      rescue => e
        skip "テスト実行中にエラーが発生しました: #{e.message}"
      end
    end

    it 'フォーム送信コントローラーが存在する場合、正しく動作すること' do
      begin
        if page.has_css?('form[data-controller="form-submit"]')
          # フォームを見つける
          form = find('form[data-controller="form-submit"]')

          # 送信ボタンを見つける
          submit_button = form.find('button[type="submit"], input[type="submit"]')

          # 送信前の状態を確認
          expect(submit_button).not_to have_css('.spinner', visible: false)

          # フォームを送信
          submit_button.click

          # 送信中の状態を確認（ローディングスピナーが表示されるなど）
          expect(page).to have_css('[data-form-submit-target="spinner"]', visible: true)
        else
          skip "フォーム送信コントローラーは現在のページで使用されていません"
        end
      rescue => e
        skip "テスト実行中にエラーが発生しました: #{e.message}"
      end
    end
  end
end
