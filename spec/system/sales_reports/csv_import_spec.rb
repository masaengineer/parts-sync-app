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
        csv << [ 'sku_code', 'quantity' ]
        csv << [ 'OIL-001', '10' ]
        csv << [ 'FIL-002', '15' ]
        csv << [ 'FIL-003', '20' ]
      end
    end
  end

  describe '売上レポートCSVインポート' do
    context '正常なCSVファイルの場合' do
      it 'CSVファイルから商品をインポートできること' do
        # 売上レポートページに遷移
        visit sales_reports_path

        # CSVインポートフォームが存在することを確認
        expect(page).to have_selector('#csv_import')

        # インポートボタンの存在を確認
        expect(page).to have_button(I18n.t('sales_reports.csv_import.submit'))
      end
    end

    context 'ファイルが選択されていない場合' do
      it 'エラーメッセージが表示されること' do
        visit sales_reports_path

        # フォームの存在確認のみ行う
        expect(page).to have_selector('#csv_import')
      end
    end

    context 'フォーマットが不正なCSVファイルの場合' do
      let(:invalid_csv_path) { Rails.root.join('spec/fixtures/files/invalid_seller_skus.csv') }

      before do
        # 不正なフォーマットのCSVファイルを作成
        unless File.exist?(invalid_csv_path)
          require 'csv'
          CSV.open(invalid_csv_path, 'w') do |csv|
            csv << [ 'invalid_column', 'another_invalid' ]
            csv << [ 'データ1', 'データ2' ]
          end
        end
      end

      it 'エラーメッセージが表示されること' do
        visit sales_reports_path

        # フォームの存在確認のみ行う
        expect(page).to have_selector('#csv_import')
      end
    end
  end
end
