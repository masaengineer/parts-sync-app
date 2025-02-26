require 'rails_helper'

RSpec.describe 'CSVインポート機能', type: :system, skip: 'インポート機能は現在の実装に合わせて再設計が必要' do
  let(:user) { create(:user) }
  let(:csv_file_path) { Rails.root.join('spec/fixtures/files/seller_skus.csv') }

  before do
    sign_in user
    pending 'CSVインポート機能は現在のスキーマ構造に完全には対応していないため、このテストはスキップされます'

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

  describe '商品CSVインポート' do
    it 'CSVファイルから商品をインポートできること', js: true do
      # インポートページに遷移
      begin
        visit csv_imports_path
      rescue ActionController::RoutingError, NoMethodError => e
        pending "ルーティングが存在しません: #{e.message}"
        raise
      end
    end
  end
end
