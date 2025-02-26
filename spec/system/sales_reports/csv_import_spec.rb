require 'rails_helper'

RSpec.describe 'CSVインポート機能', type: :system do
  let(:user) { create(:user) }
  let(:csv_file_path) { Rails.root.join('spec/fixtures/files/seller_skus.csv') }

  before do
    sign_in user
    # テスト用CSVファイルがなければ作成する
    unless File.exist?(csv_file_path)
      require 'csv'
      CSV.open(csv_file_path, 'w') do |csv|
        csv << ['sku_code', 'quantity']
        csv << ['OIL-001', '10']
        csv << ['FIL-002', '15']
        csv << ['FIL-003', '20']
      end
    end
  end

  describe '売上レポートCSVインポート' do
    context '正常なCSVファイルの場合' do
      it 'CSVファイルから商品をインポートできること', js: true do
        # 売上レポートページに遷移
        visit sales_reports_path

        # CSVインポートフォーム内の操作
        within('.csv-import-form') do
          # ファイル選択
          attach_file 'file', csv_file_path

          # インポートタイプを選択（実際の選択項目はアプリによって異なる場合がある）
          select 'Wisewill委託分シート', from: 'import_type' if has_select?('import_type')

          # インポート開始
          expect {
            click_button 'インポート'
            # インポート完了までの処理時間を考慮
            expect(page).to have_content('インポートが完了しました'), '成功メッセージが表示されません'
          }.to change { SellerSku.count }.by(3)
        end

        # インポート後に商品が表示されていることを確認
        expect(page).to have_content('OIL-001')
        expect(page).to have_content('FIL-002')
      end
    end

    context 'ファイルが選択されていない場合' do
      it 'エラーメッセージが表示されること', js: true do
        visit sales_reports_path

        within('.csv-import-form') do
          # ファイル選択せずにインポートボタンをクリック
          click_button 'インポート'

          expect(page).to have_content('ファイルを選択してください')
        end
      end
    end

    context 'フォーマットが不正なCSVファイルの場合' do
      let(:invalid_csv_path) { Rails.root.join('spec/fixtures/files/invalid_seller_skus.csv') }

      before do
        # 不正なフォーマットのCSVファイルを作成
        unless File.exist?(invalid_csv_path)
          require 'csv'
          CSV.open(invalid_csv_path, 'w') do |csv|
            csv << ['invalid_column', 'another_invalid']
            csv << ['データ1', 'データ2']
          end
        end
      end

      it 'エラーメッセージが表示されること', js: true do
        visit sales_reports_path

        within('.csv-import-form') do
          # 不正なファイル選択
          attach_file 'file', invalid_csv_path

          # インポートタイプを選択（該当する場合）
          select 'Wisewill委託分シート', from: 'import_type' if has_select?('import_type')

          # インポート開始
          expect {
            click_button 'インポート'
            expect(page).to have_content('フォーマットが不正です')
          }.not_to change(SellerSku, :count)
        end
      end
    end
  end
end
